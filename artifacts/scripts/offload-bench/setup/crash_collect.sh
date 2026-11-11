#!/usr/bin/env bash
# crash_collect.sh — read-only evidence for the 2026-11-11 15:54:53 UTC card fatal error
B=/home/opi/bench; C=$B/state/crash_20261111; mkdir -p $C
ARM() { sudo -u opi ssh -o BatchMode=yes -o ConnectTimeout=8 ubuntu@192.168.100.2 "$@"; }
echo "== host: devlink health reporters (fw_fatal holds the card's crash dump)"
devlink health show 2>&1 | tee $C/devlink_health.txt
for f in 0000:0d:00.0 0000:0d:00.1; do
  for r in fw_fatal fw; do devlink health dump show pci/$f reporter $r > $C/dump_${f}_$r.txt 2>&1; done
  echo "$f: fw_fatal dump $(wc -c < $C/dump_${f}_fw_fatal.txt) bytes, fw dump $(wc -c < $C/dump_${f}_fw.txt) bytes"
done
journalctl -k --since "2026-11-11 15:45:00" --until "2026-11-11 16:30:00" --no-pager > $C/host_kernel.txt
echo "== host: current state"
ip -br link show enp13s0f0np0; ip -br link show enp13s0f1np1
lspci -nnD -d 1af4: ; P=$(lspci -D -d 1af4:1041 | awk 'NR==1{print $1}')
[ -n "$P" ] && echo "static PF $P: sriov_numvfs=$(cat /sys/bus/pci/devices/$P/sriov_numvfs)"
virsh -c qemu:///system list --all
echo "== Arm"
if ping -c 2 -W 1 192.168.100.2 > /dev/null; then
  ARM 'echo "uptime: $(uptime -p)"; ls -d /var/log/journal 2>/dev/null && journalctl --list-boots --no-pager | tail -3' 2>&1 | tee $C/arm_boots.txt
  ARM 'journalctl -b -1 --no-pager -n 300' > $C/arm_prevboot_tail.txt 2>&1
  ARM 'journalctl -b -1 -k --no-pager | grep -iE "panic|oops|bug|watchdog|lockup|mlx5|error|fatal" | tail -60' > $C/arm_prevboot_kernel.txt 2>&1
  ARM 'journalctl -b -1 -u virtio-net-controller --no-pager -n 150' > $C/arm_prevboot_virtnet.txt 2>&1
  ARM 'systemctl is-active virtio-net-controller openvswitch-switch; sudo -n virtnet list 2>&1 | grep -E "function_type|sf_rep_net_device|vf_id" | head -20' 2>&1 | tee $C/arm_now.txt
  wc -l $C/arm_prev*.txt
else
  echo "Arm still not answering on tmfifo (it says 'DPU is ready' in the rshim log)"
fi
chown -R opi:opi $C; echo "saved in $C"
