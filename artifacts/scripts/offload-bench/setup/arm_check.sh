#!/usr/bin/env bash
# arm_check.sh — read-only: is the BF3 Arm alive, and what happened around 16:14 UTC?
echo "== host side of tmfifo"; ip -br addr show tmfifo_net0
echo "== ping Arm"; ping -c 3 -W 1 192.168.100.2 | tail -2
echo "== rshim service"; systemctl is-active rshim; ls /dev/rshim0/ 2>&1
echo "== rshim boot/log info"; cat /dev/rshim0/misc 2>/dev/null | head -20
echo "== host kernel messages since 16:00 UTC (rshim, tmfifo, virtio, mlx5, vfio)"
journalctl -k --since "$(date -u -d '2026-11-11 16:00' '+%F %T') UTC" --no-pager 2>/dev/null \
  | grep -iE "rshim|tmfifo|virtio|mlx5|vfio|0000:0d" | tail -40
echo "== last two bulk runs: which files exist"
for d in $(ls -td /home/opi/bench/results/bulk_*/r5_*/ | head -3); do echo "-- $d"; ls -l --time-style=+%T "$d" | awk 'NR>1{print $6, $5, $7}'; done
echo "== VMs"; virsh -c qemu:///system list --all
