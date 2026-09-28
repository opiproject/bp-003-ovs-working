#!/usr/bin/env bash
# opi_collect_env.sh — capture the version pins behind a benchmark run (for docs/bom.md).
# Run ON THE HOST as root:  sudo ARM=<user>@<bf3-arm-mgmt-ip> ./opi_collect_env.sh <outdir>
# Writes <outdir>/host.txt and <outdir>/arm.txt. No credentials are collected.
set -uo pipefail

ARM="${ARM:?set ARM=<user>@<bf3-arm-mgmt-ip>}"
OUT="${1:?usage: $0 <outdir>}"
mkdir -p "$OUT"
SSHA=(-o BatchMode=yes -o ConnectTimeout=8)

sec() { echo; echo "### $1"; }

{
  echo "# Host environment — captured $(date -u +%FT%TZ)"
  sec "OS";            grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
  sec "Kernel";        uname -r
  sec "CPU";           lscpu | grep -E '^(Model name|Socket|Core|Thread|CPU\(s\))'
  sec "DOCA-Host / OFED"; ofed_info -s 2>/dev/null || echo "ofed_info not found"
  dpkg-query -W -f='${Package} ${Version}\n' 'doca-*' 'mlnx-ofed-kernel*' 2>/dev/null | sort
  sec "mlx5_vdpa module"; modinfo -F description mlx5_vdpa 2>/dev/null || echo "not present"
  sec "QEMU / libvirt"; qemu-system-x86_64 --version 2>/dev/null | head -1; virsh --version 2>/dev/null
  sec "BlueField PFs"; lspci -nn -d 15b3: 2>/dev/null
  for pf in /sys/class/net/*/device; do
    n=$(basename "$(dirname "$pf")")
    [[ "$(cat "$pf/vendor" 2>/dev/null)" == "0x15b3" ]] || continue
    echo "$n: driver=$(basename "$(readlink -f "$pf/driver")") fw=$(ethtool -i "$n" 2>/dev/null | awk '/firmware-version/{print $2}') sriov_numvfs=$(cat "$pf/sriov_numvfs" 2>/dev/null)"
  done
  sec "Host eswitch (expect 'not supported' in DPU mode)"
  for d in $(devlink dev show 2>/dev/null | grep -i 'pci/0000:0d'); do devlink dev eswitch show "$d" 2>&1; done
} > "$OUT/host.txt" 2>&1

ssh "${SSHA[@]}" "$ARM" 'bash -s' > "$OUT/arm.txt" 2>&1 <<'EOF'
sec() { echo; echo "### $1"; }
echo "# BF3 Arm environment — Arm clock is not trusted; see host.txt for capture time"
sec "OS";          grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
sec "Kernel";      uname -r
sec "Cores";       nproc
sec "BFB / DOCA";  (sudo -n bfver 2>/dev/null || bfver 2>/dev/null) | head -20
cat /etc/mlnx-release 2>/dev/null
dpkg-query -W -f='${Package} ${Version}\n' 'doca-*' 'mlnx-ofed-kernel*' 'mlnx-dpdk*' 2>/dev/null | sort | head -40
sec "OVS";         ovs-vswitchd --version 2>/dev/null | head -1
sec "OVS other_config"; sudo -n ovs-vsctl get Open_vSwitch . other_config
sec "OVS doca/dpdk"; sudo -n ovs-vsctl list Open_vSwitch | grep -E 'doca_(initialized|version)|dpdk_(initialized|version)'
sec "Uplink firmware"; for i in p0 p1; do echo "$i: $(ethtool -i $i 2>/dev/null | awk '/firmware-version|^driver/{printf "%s ", $0}')"; done
sec "Eswitch mode"; for d in $(devlink dev show 2>/dev/null); do echo "$d: $(devlink dev eswitch show $d 2>&1)"; done
sec "Representors"; ip -br link | grep -E '^(p[01]|pf[01]hpf|pf[01]vf|en3f)' || true
EOF

echo "wrote $OUT/host.txt and $OUT/arm.txt"
echo "Before committing: grep -nE '172\.22\.|password' $OUT/*.txt  (redact lab mgmt IPs if required)"
