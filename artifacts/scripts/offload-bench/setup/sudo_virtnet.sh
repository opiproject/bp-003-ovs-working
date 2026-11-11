#!/usr/bin/env bash
# sudo_virtnet.sh — BF3 ARM, run with sudo. Lets user ubuntu run virtnet and "ip link set <dev> up" without a password.
set -euo pipefail
[ "$(hostname)" = dh5bf3 ] && [ $EUID -eq 0 ] || { echo "run on the Arm with sudo"; exit 1; }
V=$(command -v virtnet); I=$(command -v ip)
F=/etc/sudoers.d/opi-virtnet
echo "ubuntu ALL=(root) NOPASSWD: $V, $I link set * up" > $F
chmod 440 $F
if visudo -cf $F; then echo "rule added: $(cat $F)"; else rm -f $F; echo "invalid rule, removed"; exit 1; fi
echo "$(date -u +%FT%TZ) added $F. Undo: rm $F" >> /opt/opi_experiment/CHANGELOG
