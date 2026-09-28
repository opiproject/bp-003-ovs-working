#!/usr/bin/env bash
# opi_arm_prep.sh — one-time prep ON THE BF3 ARM.
# Usage (from the dir holding both scripts):  sudo bash opi_arm_prep.sh
#  1. backs up the current OVS + firmware config (your only record of the working setup)
#  2. installs sysstat (mpstat) for CPU measurement
#  3. installs opi_arm_mode.sh to /usr/local/sbin
#  4. adds a scoped NOPASSWD sudoers drop-in so the host can drive benchmarks
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
USER_NAME="${SUDO_USER:-ubuntu}"
TS=$(date -u +%Y%m%dT%H%M%SZ)
BK=/opt/opi_experiment/backup/$TS
mkdir -p "$BK"

echo "== backup -> $BK"
ovs-vsctl show                 > "$BK/ovs-vsctl-show.txt"
ovs-vsctl list Open_vSwitch    > "$BK/open_vswitch.txt"
for br in $(ovs-vsctl list-br); do
  echo "$br $(ovs-vsctl get bridge "$br" datapath_type): $(ovs-vsctl list-ports "$br" | tr '\n' ' ')"
done > "$BK/bridges.txt"
cat "$(readlink -f /etc/openvswitch/conf.db)" > "$BK/conf.db"   # real copy, not the symlink
ip -br link                    > "$BK/ip-link.txt"
ip -br addr                    > "$BK/ip-addr.txt"
devlink dev eswitch show       > "$BK/eswitch.txt" 2>&1 || true
( mst start >/dev/null 2>&1 || true
  for d in /dev/mst/*; do [[ -e $d ]] && { echo "== $d"; mlxconfig -d "$d" q; }; done
) > "$BK/mlxconfig.txt" 2>&1 || true
cat "$BK/bridges.txt"

echo "== packages"
command -v mpstat >/dev/null || { apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sysstat; }

echo "== install mode script"
install -m 0755 "$HERE/opi_arm_mode.sh" /usr/local/sbin/opi_arm_mode.sh

echo "== sudoers drop-in for $USER_NAME"
F=/etc/sudoers.d/opi-benchmark
cat > "$F.tmp" <<EOF
# OPI OVS-offload benchmark — scoped, remove with: rm $F
$USER_NAME ALL=(root) NOPASSWD: /usr/local/sbin/opi_arm_mode.sh, /usr/bin/ovs-vsctl, /usr/bin/ovs-appctl
EOF
visudo -cf "$F.tmp" && mv "$F.tmp" "$F" && chmod 0440 "$F"

echo
echo "Done. Restore original OVS DB if ever needed:"
echo "  sudo systemctl stop openvswitch-switch && sudo sh -c \"cat $BK/conf.db > \$(readlink -f /etc/openvswitch/conf.db)\" && sudo systemctl start openvswitch-switch"
/usr/local/sbin/opi_arm_mode.sh status
