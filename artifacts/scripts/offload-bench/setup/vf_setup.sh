#!/usr/bin/env bash
set -euo pipefail
[ "$(hostname)" = dh5 ] || { echo "not dh5"; exit 1; }
ARM() { sudo -u opi ssh -o BatchMode=yes ubuntu@192.168.100.2 "$@"; }
TS=$(date -u +%Y%m%dT%H%M%SZ); ST=/home/opi/bench/state; mkdir -p $ST

# 1. before state of the Arm OVS
ARM 'hostname; sudo -n ovs-vsctl show' > $ST/ovs_before_vf_$TS.txt

# 2. one VF per PF, bound to vfio-pci (not to mlx5_core on the host)
modprobe vfio-pci
for pf in enp13s0f0np0 enp13s0f1np1; do
  d=/sys/class/net/$pf/device
  [ "$(cat $d/sriov_numvfs)" = 0 ] || { echo "$pf already has VFs, stopping (may not be ours)"; exit 1; }
  echo 0 > $d/sriov_drivers_autoprobe
  echo 1 > $d/sriov_numvfs
  vf=$(basename "$(readlink $d/virtfn0)")
  echo vfio-pci > /sys/bus/pci/devices/$vf/driver_override
  echo $vf > /sys/bus/pci/drivers_probe
  echo "== $pf VF0 = $vf"; lspci -k -s $vf
done

# 3. representors on the Arm, into the matching bridge
sleep 3
ARM 'ip -br link | grep -E "pf[01]vf0"'
ARM 'sudo -n ovs-vsctl --may-exist add-port ovsbr1 pf0vf0; sudo -n ovs-vsctl --may-exist add-port ovsbr2 pf1vf0; sudo -n ovs-vsctl show'

# 4. change log
cat >> /home/opi/bench/CHANGELOG.md <<LOG
- $TS VF passthrough setup: 1 VF on each PF (autoprobe off, bound to vfio-pci); Arm: pf0vf0 -> ovsbr1, pf1vf0 -> ovsbr2.
  Undo: detach VFs from VMs; Arm: ovs-vsctl del-port pf0vf0; del-port pf1vf0; host: echo 0 > /sys/class/net/<pf>/device/sriov_numvfs
  Before: $ST/ovs_before_vf_$TS.txt
LOG
echo "done"
