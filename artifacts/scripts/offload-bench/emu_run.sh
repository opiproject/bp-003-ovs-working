#!/usr/bin/env bash
# emu_run.sh — step 3: virtio-net emulation VFs into both VMs, then bulk + step-4 suite.
# Run on dh5 as root. Assumes: static virtio PF present (1af4:1041), VMs shut off, Arm in tc mode.
set -euo pipefail
[ "$(hostname)" = dh5 ] && [ "$(whoami)" = root ] || { echo "run on dh5 as root"; exit 1; }
B=/home/opi/bench; V="virsh -c qemu:///system"; TS=$(date -u +%Y%m%dT%H%M%SZ); ST=$B/state; mkdir -p $ST
ARM() { sudo -u opi ssh -o BatchMode=yes -o ConnectTimeout=8 ubuntu@192.168.100.2 "$@"; }
G()   { ssh -i /home/opi/.ssh/opi_bench -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new ubuntu@"$@"; }
VMS=(bench-vm1 bench-vm2); declare -A IP=([bench-vm1]=192.168.123.253 [bench-vm2]=192.168.123.254)
declare -A EIP=([bench-vm1]=10.99.2.1 [bench-vm2]=10.99.2.2)

# ---- 0. preconditions ----
PF=$(lspci -D -d 1af4:1041 | awk 'NR==1{print $1}')
[ -n "$PF" ] || { echo "no static virtio-net PF on the host"; exit 1; }
for vm in "${VMS[@]}"; do [ "$($V domstate $vm)" = "shut off" ] || { echo "$vm is not shut off"; exit 1; }; done
[ "$(cat /sys/bus/pci/devices/$PF/sriov_numvfs)" = 0 ] || { echo "$PF already has VFs, stopping"; exit 1; }
echo "static PF: $PF"

# ---- 1. two virtio VFs, bound to vfio-pci ----
modprobe vfio-pci
echo 0 > /sys/bus/pci/devices/$PF/sriov_drivers_autoprobe
echo 2 > /sys/bus/pci/devices/$PF/sriov_numvfs
VF=()
for i in 0 1; do
  v=$(basename "$(readlink /sys/bus/pci/devices/$PF/virtfn$i)")
  echo vfio-pci > /sys/bus/pci/devices/$v/driver_override
  echo $v > /sys/bus/pci/drivers_probe
  echo "VF$i = $v  driver=$(basename "$(readlink -f /sys/bus/pci/devices/$v/driver)")  group=$(ls /sys/bus/pci/devices/$v/iommu_group/devices | tr '\n' ' ')"
  VF+=("$v")
done

# ---- 2. Arm: wait for the VF devices, add their SF representors to ovsbr1 ----
ARM 'cat > /tmp/vn.py' <<'PY'
import json, sys
t = sys.stdin.read(); t = t[t.index("\n") + 1:] if t.startswith('{"rpc') else t
for x in json.loads(t).get("devices", []):
    print(str(x.get("function_type")).replace(" ", "_"), x.get("vf_id"), x.get("sf_rep_net_device"), x.get("mac"), x.get("vuid"))
PY
REPS=""
for i in $(seq 1 30); do
  ARM 'sudo -n virtnet list | python3 /tmp/vn.py' > $ST/virtnet_devices_$TS.txt 2>&1 || true
  REPS=$(awk '$1 ~ /VF/ && $3 != "None" {print $3}' $ST/virtnet_devices_$TS.txt)
  [ "$(echo "$REPS" | grep -c .)" -ge 2 ] && break; sleep 2
done
cat $ST/virtnet_devices_$TS.txt
[ "$(echo "$REPS" | grep -c .)" -ge 2 ] || { echo "controller did not report 2 VF representors"; exit 1; }
for r in $REPS; do ARM "sudo -n ovs-vsctl --may-exist add-port ovsbr1 $r; sudo -n ip link set $r up"; done
ARM 'sudo -n ovs-vsctl list-ports ovsbr1'

# ---- 3. attach VF0 -> vm1, VF1 -> vm2, start ----
for n in 0 1; do
  vm=${VMS[$n]}; v=${VF[$n]}
  cat > $ST/emu_hostdev_$vm.xml <<X
<hostdev mode='subsystem' type='pci' managed='no'>
  <source><address domain='0x${v:0:4}' bus='0x${v:5:2}' slot='0x${v:8:2}' function='0x${v:11:1}'/></source>
</hostdev>
X
  $V attach-device $vm $ST/emu_hostdev_$vm.xml --config
  $V start $vm
done
for vm in "${VMS[@]}"; do until G ${IP[$vm]} true 2>/dev/null; do sleep 3; done; done

# ---- 4. inside each guest: the 06:99:... virtio NIC becomes emu0 ----
for vm in "${VMS[@]}"; do
  echo "== $vm"
  G ${IP[$vm]} "bash -s ${EIP[$vm]}" <<'GS'
set -e
n=""
for i in $(seq 1 15); do
  for d in /sys/class/net/*; do case "$(cat $d/address 2>/dev/null)" in 06:99:*) n=$(basename $d);; esac; done
  [ -n "$n" ] && break; sleep 1
done
[ -n "$n" ] || { echo "no emulated (06:99:...) NIC in this guest"; ip -br link; exit 1; }
[ "$n" = emu0 ] || { sudo ip link set "$n" down; sudo ip link set "$n" name emu0; }
sudo ip addr replace $1/24 dev emu0
sudo ip link set emu0 up
sudo ethtool -L emu0 combined 4 2>/dev/null || true
sudo ip link set test0 down
sleep 3
ip -br addr show emu0; ethtool -i emu0 | head -1; ethtool -l emu0 | tail -5; ethtool -k emu0 | grep -E "^(tcp-segmentation|generic-receive|large-receive)"
GS
done

# ---- 5. path check ----
G ${IP[bench-vm1]} "ping -c 3 -W 2 10.99.2.2"

# ---- 6. change log, then the tests (as opi, in tmux) ----
cat >> $B/CHANGELOG.md <<LOG
- $TS emulation: 2 virtio VFs on static PF $PF (${VF[0]} -> bench-vm1 emu0 10.99.2.1, ${VF[1]} -> bench-vm2 emu0 10.99.2.2), vfio-pci, autoprobe 0.
  Arm: SF reps [$(echo $REPS)] added to ovsbr1. test0 DOWN in guests (not persistent).
  Undo: shut VMs; virsh detach-device <vm> $ST/emu_hostdev_<vm>.xml --config; echo 0 > /sys/bus/pci/devices/$PF/sriov_numvfs; Arm: ovs-vsctl del-port <rep>.
LOG
ARM "for r in $(echo $REPS); do echo \"== \$r\"; ethtool -S \$r; done" > $ST/emu_reps_before_$TS.txt 2>&1 || true
sudo -iu opi tmux new -s emu -d "cd ~/bench && DST=10.99.2.2 TNIC=emu0 ROUNDS=5 ./bench_bulk.sh sw tc doca 2>&1 | tee ~/bench/bulk_emu.log; DST=10.99.2.2 TNIC=emu0 ROUNDS=3 ./bench_suite.sh sw tc doca 2>&1 | tee ~/bench/suite_emu.log"
echo "Started: bulk (15 runs, ~25 min) then suite (9 runs, ~50 min)."
echo "Progress: grep -c 'done:' $B/bulk_emu.log  (15)   then   grep -c 'done:' $B/suite_emu.log  (9)"
