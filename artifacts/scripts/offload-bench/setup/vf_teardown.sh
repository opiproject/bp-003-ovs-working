#!/usr/bin/env bash
set -euo pipefail
[ "$(hostname)" = dh5 ] && [ "$(whoami)" = root ] || { echo "run on dh5 as root"; exit 1; }
B=/home/opi/bench; V="virsh -c qemu:///system"
ARM() { sudo -u opi ssh -o BatchMode=yes ubuntu@192.168.100.2 "$@"; }
for vm in bench-vm1 bench-vm2; do $V shutdown $vm || true; done
while $V list --name | grep -q bench-vm; do sleep 2; done
for vm in bench-vm1 bench-vm2; do $V detach-device $vm $B/state/hostdev_$vm.xml --config; done
for pf in enp13s0f0np0 enp13s0f1np1; do
  d=/sys/class/net/$pf/device; echo 0 > $d/sriov_numvfs; echo 1 > $d/sriov_drivers_autoprobe
done
ARM 'sudo -n ovs-vsctl --if-exists del-port ovsbr1 pf0vf0; sudo -n ovs-vsctl --if-exists del-port ovsbr2 pf1vf0; sudo -n ovs-vsctl list-ports ovsbr1; sudo -n ovs-vsctl list-ports ovsbr2'
for vm in bench-vm1 bench-vm2; do echo "$vm hostdevs left: $($V dumpxml --inactive $vm | grep -c '<hostdev' || true)"; done
echo "- $(date -u +%FT%TZ) VF passthrough removed: hostdevs detached, sriov_numvfs=0, autoprobe=1, pf0vf0/pf1vf0 removed from Arm bridges. VMs left shut off for the power cycle." >> $B/CHANGELOG.md
echo "teardown done"
