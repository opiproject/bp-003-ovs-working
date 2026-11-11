#!/usr/bin/env bash
set -u
ARM() { sudo -u opi ssh -o BatchMode=yes -o ConnectTimeout=8 ubuntu@192.168.100.2 "$@"; }
echo "== host"; hostname; uname -r; modinfo -F version mlx5_core
ip addr show tmfifo_net0 | grep -q 192.168.100.1 || { ip addr add 192.168.100.1/24 dev tmfifo_net0; ip link set tmfifo_net0 up; echo "tmfifo address re-added"; }
cpupower frequency-set -g performance > /dev/null && echo "governor set to performance"
echo "== virtio-net functions on the host (expect one static PF, 1af4:1041)"
lspci -nnD -d 1af4:
for f in $(lspci -D -d 1af4:1041 | awk '{print $1}'); do
  echo "$f driver=$(basename "$(readlink -f /sys/bus/pci/devices/$f/driver)" 2>/dev/null) totalvfs=$(cat /sys/bus/pci/devices/$f/sriov_totalvfs 2>/dev/null) iommu_group=$(basename "$(readlink -f /sys/bus/pci/devices/$f/iommu_group)")"
done
echo "== mlx5 PFs"; ip -br link show enp13s0f0np0; ip -br link show enp13s0f1np1
sleep 5
echo "== BF3 Arm"
ARM 'hostname; echo "controller: $(systemctl is-active virtio-net-controller)"; sudo -n virtnet list 2>&1 | head -40; sudo -n ovs-vsctl show | grep -E "Bridge|Port"'
