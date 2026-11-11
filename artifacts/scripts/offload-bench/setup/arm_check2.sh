#!/usr/bin/env bash
echo "== Arm reachable now?"; ping -c 2 -W 1 192.168.100.2 | tail -1
echo "== rshim boot log (full)"; sed -n '/Log Messages/,$p' /dev/rshim0/misc
echo "== host kernel 15:50-16:25 UTC, all card/virtio/vfio lines (first 60)"
journalctl -k --since "2026-11-11 15:50:00" --until "2026-11-11 16:25:00" --no-pager \
  | grep -iE "rshim|tmfifo|virtio|mlx5|vfio|0000:0d|DMAR|AER|iommu" | head -60
echo "== same window, everything else the kernel said (first 30)"
journalctl -k --since "2026-11-11 15:50:00" --until "2026-11-11 16:24:40" --no-pager | grep -viE "mlx5|virtio|vfio" | head -30
