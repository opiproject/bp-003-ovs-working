#!/usr/bin/env bash
set -euo pipefail
[ "$(hostname)" = dh5 ] && [ "$(whoami)" = root ] || { echo "run on dh5 as root"; exit 1; }
B=/home/opi/bench; V="virsh -c qemu:///system"; TS=$(date -u +%Y%m%dT%H%M%SZ)
G() { ssh -i /home/opi/.ssh/opi_bench -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new ubuntu@"$@"; }
declare -A IP=([bench-vm1]=192.168.123.253 [bench-vm2]=192.168.123.254)
declare -A SLOT=([bench-vm1]=0x00 [bench-vm2]=0x02)
declare -A VFIP=([bench-vm1]=10.99.1.1 [bench-vm2]=10.99.1.2)

# 0. quick checks
echo "== 'File exists' lines in the before-state (non-zero = old problem, not ours):"
grep -c "File exists" $B/state/ovs_before_vf_*.txt || true
echo "== IOMMU groups (each should contain only its own VF):"
ls /sys/bus/pci/devices/0000:0d:00.3/iommu_group/devices /sys/bus/pci/devices/0000:0d:02.3/iommu_group/devices

# 1. lib.sh: destination and test NIC overridable (identical to the repo copy)
cp $B/lib.sh $B/state/lib.sh.before_vf_$TS
cat > $B/lib.sh <<'LIB'
# ~/bench/lib.sh — settings and helpers shared by every test script (sourced, not run)
VM1=192.168.123.253; VM2=192.168.123.254; DST=${DST:-10.99.0.2}; TNIC=${TNIC:-test0}
KEY=$HOME/.ssh/opi_bench; ARM=${ARM:-ubuntu@192.168.100.2}
PF0=enp13s0f0np0; PF1=enp13s0f1np1
VIRSH="virsh -c qemu:///system"
vm1() { ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 ubuntu@$VM1 "$@"; }
vm2() { ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 ubuntu@$VM2 "$@"; }
arm() { ssh -o BatchMode=yes -o ConnectTimeout=8 "$ARM" "$@"; }
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$RUN/run.log"; }

snap() {  # snap <dir> <before|after> — drop/error counters at every hop
  local d=$1 t=$2 v n f
  for v in 1 2; do vm$v "echo '== nstat'; nstat -az; echo '== $TNIC'; ethtool -S $TNIC" > "$d/vm${v}_$t.txt" 2>&1; done
  { echo "== $PF0"; ethtool -S $PF0; echo "== $PF1"; ethtool -S $PF1
    for n in /sys/class/net/macvtap*; do echo "== ${n##*/}"; for f in $n/statistics/*; do echo "${f##*/} $(cat $f)"; done; done
  } > "$d/host_$t.txt" 2>&1
  arm 'for i in p0 p1 pf0hpf pf1hpf pf0vf0 pf1vf0; do echo "== $i"; ethtool -S $i; done; echo "== offload-stats"; sudo -n ovs-appctl dpctl/offload-stats-show' > "$d/arm_$t.txt" 2>&1
}

meta() {  # meta <dir> <mode> — everything needed to reproduce this run
  { echo "mode=$2 date=$(date -u +%FT%TZ) DST=$DST TNIC=$TNIC"; uname -r; cpupower frequency-info -p
    $VIRSH vcpupin bench-vm1; $VIRSH vcpupin bench-vm2; $VIRSH emulatorpin bench-vm1; $VIRSH emulatorpin bench-vm2
    vm1 'uname -r; iperf3 --version | head -1'; vm1 "ethtool -l $TNIC"; vm2 "ethtool -l $TNIC"; } > "$1/meta.txt" 2>&1
  arm 'sudo -n /usr/local/sbin/opi_arm_mode.sh status' >> "$1/meta.txt" 2>&1
}
LIB
chown opi:opi $B/lib.sh

# 2. guest-side setup script (runs inside each VM)
cat > $B/state/vf_guest.sh <<'GS'
set -e
IPADDR=$1
modinfo -F filename mlx5_core >/dev/null 2>&1 || { sudo apt-get update -qq; sudo apt-get install -y -qq linux-modules-extra-$(uname -r); }
sudo modprobe mlx5_core
n=""
for i in $(seq 1 15); do
  for d in /sys/class/net/*; do
    [ "$(basename "$(readlink -f $d/device/driver 2>/dev/null)" 2>/dev/null)" = mlx5_core ] && n=$(basename $d)
  done
  [ -n "$n" ] && break; sleep 1
done
[ -n "$n" ] || { echo "no mlx5 interface in this guest"; exit 1; }
echo "VF interface found: $n"
[ "$n" = vf0 ] || { sudo ip link set "$n" down; sudo ip link set "$n" name vf0; }
sudo ip addr replace $IPADDR/24 dev vf0
sudo ip link set vf0 up
sudo ip link set test0 down
sleep 3
ip -br addr show vf0; ethtool -i vf0 | head -2; ethtool -l vf0 | tail -5
GS

# 3. shut down, attach the VF to each VM, start
for vm in bench-vm1 bench-vm2; do $V shutdown $vm; done
while $V list --name | grep -q bench-vm; do sleep 2; done
for vm in bench-vm1 bench-vm2; do
  cat > $B/state/hostdev_$vm.xml <<X
<hostdev mode='subsystem' type='pci' managed='no'>
  <source><address domain='0x0000' bus='0x0d' slot='${SLOT[$vm]}' function='0x3'/></source>
</hostdev>
X
  $V attach-device $vm $B/state/hostdev_$vm.xml --config
  $V start $vm
done
for vm in bench-vm1 bench-vm2; do until G ${IP[$vm]} true 2>/dev/null; do sleep 3; done; done

# 4. configure the VF inside each guest
for vm in bench-vm1 bench-vm2; do
  echo "== $vm"; G ${IP[$vm]} "bash -s ${VFIP[$vm]}" < $B/state/vf_guest.sh
done

# 5. path check over the VFs
G ${IP[bench-vm1]} "ping -c 3 -W 2 10.99.1.2"

# 6. change log, then benchmark (as opi, in tmux)
cat >> $B/CHANGELOG.md <<LOG
- $TS VFs attached: 0d:00.3 -> bench-vm1 (vf0 10.99.1.1), 0d:02.3 -> bench-vm2 (vf0 10.99.1.2); test0 set DOWN in both guests (not persistent).
  lib.sh: DST/TNIC overridable, Arm snap includes pf0vf0/pf1vf0. Before: $B/state/lib.sh.before_vf_$TS
  Undo: shut down VMs; virsh detach-device <vm> $B/state/hostdev_<vm>.xml --config; start (test0 comes back up on boot).
LOG
sudo -iu opi tmux new -s benchvf -d "cd ~/bench && DST=10.99.1.2 TNIC=vf0 ROUNDS=5 ./bench_bulk.sh sw tc doca 2>&1 | tee ~/bench/bulk_vf.log"
echo "VF benchmark running. Progress: grep -c 'done:' /home/opi/bench/bulk_vf.log  (15 = finished)"
