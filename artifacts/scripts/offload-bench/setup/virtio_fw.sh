#!/usr/bin/env bash
# virtio_fw.sh — BF3 ARM, run with sudo. Enables virtio-net emulation (1 static PF, 16 VFs) and writes virtnet.conf.
# Takes effect only after a cold power cycle. Run on 11 Nov 2026 (DOCA 3.5, BFB 3.5.0-89).
set -euo pipefail
[ "$(hostname)" = dh5bf3 ] || { echo "not the BF3 Arm, stopping"; exit 1; }
[ $EUID -eq 0 ] || { echo "run with sudo"; exit 1; }
for d in 03:00.0 03:00.1; do lspci -s $d | grep -qi mellanox || { echo "$d is not a Mellanox function, stopping"; exit 1; }; done
ls /sys/class/infiniband | grep -qx mlx5_0 && ls /sys/class/infiniband | grep -qx mlx5_1 || { echo "RDMA devices are not mlx5_0/mlx5_1:"; ls /sys/class/infiniband; exit 1; }

BK=/opt/opi_experiment/backup/virtio_$(date -u +%Y%m%dT%H%M%SZ); mkdir -p $BK/recovery
for d in 03:00.0 03:00.1; do mlxconfig -d $d -e q > $BK/mlxconfig_$d.txt; done
ovs-vsctl show > $BK/ovs.txt
if [ -f /opt/mellanox/mlnx_virtnet/virtnet.conf ]; then cp -a /opt/mellanox/mlnx_virtnet/virtnet.conf $BK/; echo "== old virtnet.conf"; cat $BK/virtnet.conf; fi
mv /opt/mellanox/mlnx_virtnet/recovery/* $BK/recovery/ 2>/dev/null || true
echo "before-state saved in $BK"

mlxconfig -y -d 03:00.0 s VIRTIO_NET_EMULATION_ENABLE=1 VIRTIO_NET_EMULATION_NUM_PF=1 VIRTIO_NET_EMULATION_NUM_VF=16 \
  VIRTIO_NET_EMULATION_NUM_MSIX=64 VIRTIO_NET_EMULATION_NUM_VF_MSIX=18 PCI_SWITCH_EMULATION_ENABLE=0 \
  PCI_SWITCH_EMULATION_NUM_PORT=0 PER_PF_NUM_SF=1 PF_TOTAL_SF=64 PF_BAR2_ENABLE=0 PF_SF_BAR_SIZE=8 SRIOV_EN=1
mlxconfig -y -d 03:00.1 s PER_PF_NUM_SF=1 PF_TOTAL_SF=64 PF_BAR2_ENABLE=0 PF_SF_BAR_SIZE=8

mkdir -p /opt/mellanox/mlnx_virtnet
cat > /opt/mellanox/mlnx_virtnet/virtnet.conf <<'J'
{
  "ib_dev_p0": "mlx5_0",
  "ib_dev_p1": "mlx5_1",
  "ib_dev_for_static_pf": "mlx5_0",
  "is_lag": 0,
  "static_pf": { "mac_base": "06:99:00:00:00:00", "mtu": 1500 },
  "vf": { "mac_base": "06:99:00:00:10:00", "vfs_per_pf": 16, "max_queue_pairs": 4, "mtu": 1500 }
}
J
python3 -m json.tool /opt/mellanox/mlnx_virtnet/virtnet.conf > /dev/null && echo "virtnet.conf is valid JSON"
echo "== next-boot values"
for d in 03:00.0 03:00.1; do echo "-- $d"; mlxconfig -d $d q | grep -E "VIRTIO_NET_EMULATION|PCI_SWITCH_EMULATION|PER_PF_NUM_SF|PF_TOTAL_SF|PF_BAR2_ENABLE|PF_SF_BAR_SIZE|SRIOV_EN|NUM_OF_VFS"; done
echo "$BK: virtio-net emulation firmware set, virtnet.conf written. Undo: mlxconfig with values in $BK/mlxconfig_*.txt, restore $BK/virtnet.conf, power cycle." | tee -a /opt/opi_experiment/CHANGELOG
