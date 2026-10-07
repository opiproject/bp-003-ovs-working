#!/usr/bin/env bash
# opi_emu_bench.sh — macvtap vs BF3 virtio-net emulation, run FROM HOST dh5.
#
# Each round runs two paths back-to-back between the same two VMs:
#   macvtap : guest virtio-net on macvtap over the host PF (host vhost-net carries packets)
#   emu     : guest virtio-net on a BF3-emulated virtio device (1af4:1041) passed in with VFIO
#
# The Arm OVS datapath is NOT switched by this script. Put the Arm in the mode you want
# first (kernel+TC or OVS-DOCA) and pass it as DP= so it is recorded with every row.
#
# Usage:  sudo DP=tc   ROUNDS=3 ./opi_emu_bench.sh
#         sudo DP=doca ROUNDS=3 ./opi_emu_bench.sh
#
# Per run it records:
#   host   mpstat (host kernel = %sys+%soft+%irq, VMs = %guest) and pidstat -t (vhost-* threads)
#   vm2    mpstat (receiver busy) and interface drop counters before/after
#   Arm    mpstat, and dpctl/dump-flows -m at t = DUR/2 (mid-run, while flows are live)
#   iperf3 -J from vm1; throughput is read from SENDER totals (sum_sent): the receiver
#          total can overstate the test duration (esnet/iperf#836). Both are kept in the CSV.
# Output: $OUT/<ts>_r<N>_<dp>-<path>/ and one row per run in $OUT/summary.csv
set -euo pipefail

# ---- settings (override via env) -------------------------------------------
ARM="${ARM:-ubuntu@172.22.222.3}"          # BF3 Arm, needs NOPASSWD for ovs-appctl
VM1="${VM1:-192.168.122.253}"               # sender  (SSH on libvirt default net)
VM2="${VM2:-192.168.122.254}"               # receiver
MACVTAP_DST="${MACVTAP_DST:-10.99.0.2}"     # vm2 address on test0 (macvtap)
MACVTAP_IF="${MACVTAP_IF:-test0}"
EMU_DST="${EMU_DST:-10.98.0.2}"             # vm2 address on ens7 (emulated device)
EMU_IF="${EMU_IF:-ens7}"
DP="${DP:?set DP=tc or DP=doca (the Arm OVS mode you put it in)}"
ROUNDS="${ROUNDS:-3}"; DUR="${DUR:-60}"; STREAMS="${STREAMS:-8}"
OUT="${OUT:-/root/emu-bench}"               # new folder: its CSV columns differ from the hand-run emu-run/summary.csv
KEY="${KEY:-/root/.ssh/id_ed25519}"
PATHS="${PATHS:-macvtap emu}"

SSHV=(-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i "$KEY")
SSHA=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8)
vm()  { local ip=$1; shift; ssh "${SSHV[@]}" ubuntu@"$ip" "$@"; }
arm() { ssh "${SSHA[@]}" "$ARM" "$@"; }
log() { echo "[$(date -u +%FT%TZ)] $*"; }
need(){ command -v "$1" >/dev/null || { echo "missing $1 on host (apt install sysstat iperf3)"; exit 1; }; }

need mpstat; need pidstat; need python3
mkdir -p "$OUT"
HOST_CPUS=$(nproc)

# ---- preflight --------------------------------------------------------------
log "preflight (DP=$DP, $ROUNDS rounds, ${DUR}s x $STREAMS streams)"
arm 'command -v mpstat >/dev/null && sudo -n ovs-appctl version >/dev/null' \
  || { echo "Arm: need sysstat and NOPASSWD sudo for ovs-appctl"; exit 1; }
ARM_CPUS=$(arm nproc)
ARM_CFG=$(arm 'sudo -n ovs-vsctl get Open_vSwitch . other_config' 2>/dev/null || echo '?')
log "Arm other_config: $ARM_CFG"
case "$DP" in
  doca) [[ $ARM_CFG == *doca-init* ]] || { echo "DP=doca but Arm has no doca-init"; exit 1; } ;;
  tc)   [[ $ARM_CFG != *doca-init* ]] || { echo "DP=tc but Arm is in OVS-DOCA mode"; exit 1; } ;;
esac
for P in $PATHS; do
  case $P in macvtap) DST=$MACVTAP_DST ;; emu) DST=$EMU_DST ;; *) echo "unknown path $P"; exit 1 ;; esac
  vm "$VM1" "ping -c 2 -W 2 $DST >/dev/null" || { echo "vm1 cannot reach $DST ($P)"; exit 1; }
done
if [[ " $PATHS " == *" emu "* ]]; then
  vm "$VM1" "ethtool -i $EMU_IF | grep -q 'driver: virtio_net'" \
    || { echo "vm1 $EMU_IF is not on virtio_net"; exit 1; }
  vm "$VM1" "lspci -nn | grep -q '1af4:1041'" || { echo "vm1 has no 1af4:1041 device"; exit 1; }
fi

# ---- one measured run -------------------------------------------------------
run_one() {  # $1=path  $2=round
  local P=$1 R=$2 DST IF D TS
  case $P in macvtap) DST=$MACVTAP_DST IF=$MACVTAP_IF ;; emu) DST=$EMU_DST IF=$EMU_IF ;; esac
  TS=$(date -u +%Y%m%dT%H%M%SZ)
  D="$OUT/${TS}_r${R}_${DP}-${P}"; mkdir -p "$D"
  log "round $R  $DP-$P  -> $DST ($IF)  dir $D"

  vm "$VM2" 'pkill -x iperf3 || true; iperf3 -s -D'; sleep 1
  vm "$VM2" "ip -s -s link show $IF" > "$D/vm2_link_before.txt" 2>&1 || true

  mpstat 1 "$DUR"                 > "$D/host_mpstat.txt"   2>&1 &  local M1=$!
  pidstat -u -t 1 "$DUR"          > "$D/host_pidstat.txt"  2>&1 &  local M2=$!
  vm  "$VM2" "mpstat 1 $DUR"      > "$D/vm2_mpstat.txt"    2>&1 &  local M3=$!
  arm "mpstat 1 $DUR"             > "$D/arm_mpstat.txt"    2>&1 &  local M4=$!
  vm  "$VM1" "iperf3 -c $DST -t $DUR -P $STREAMS -J" > "$D/iperf.json" &  local IP=$!

  sleep $((DUR / 2))
  arm 'sudo -n ovs-appctl dpctl/dump-flows -m' > "$D/flows_mid.txt" 2>&1 || true
  arm 'sudo -n ovs-appctl dpif/show'           > "$D/dpif_mid.txt"  2>&1 || true

  wait $IP || log "iperf3 exited non-zero"
  wait $M1 $M2 $M3 $M4 || true
  vm "$VM2" "ip -s -s link show $IF" > "$D/vm2_link_after.txt" 2>&1 || true
  vm "$VM2" 'pkill -x iperf3 || true'
  echo "DP=$DP PATH=$P ROUND=$R DST=$DST IF=$IF DUR=$DUR STREAMS=$STREAMS ARM_CFG=$ARM_CFG" > "$D/meta.txt"

  python3 - "$D" "$OUT/summary.csv" "$HOST_CPUS" "$ARM_CPUS" "$DP" "$P" "$R" <<'PY'
import csv, json, os, re, sys
d, csvp, hcpu, acpu, dp, path, rnd = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), *sys.argv[5:]

def mpstat_avg(fn):
    """Return the 'Average: all' row of an mpstat file as {column: value}."""
    hdr = None
    try:
        for line in open(fn):
            f = line.split()
            if len(f) > 2 and f[0] == "Average:" and f[1] == "CPU": hdr = f
            elif hdr and len(f) > 2 and f[0] == "Average:" and f[1] == "all":
                return {h: float(v) for h, v in zip(hdr[2:], f[2:])}
    except OSError: pass
    return {}

def vhost_cores(fn):
    """Sum %CPU of vhost-* threads in pidstat -t Average lines (100 % = 1 core)."""
    hdr, tot = None, 0.0
    try:
        for line in open(fn):
            f = line.split()
            if len(f) > 3 and f[0] == "Average:" and "%CPU" in f: hdr = f
            elif hdr and len(f) == len(hdr) and f[0] == "Average:" and "vhost-" in f[-1]:
                tot += float(f[hdr.index("%CPU")])
    except OSError: pass
    return tot / 100

row = {"run": os.path.basename(d), "round": rnd, "dp": dp, "path": path}
try:
    e = json.load(open(os.path.join(d, "iperf.json")))["end"]
    s, r = e["sum_sent"], e["sum_received"]
    row["gbps_sent"] = round(s["bits_per_second"] / 1e9, 2)
    row["gbps_recv"] = round(r["bits_per_second"] / 1e9, 2)
    row["retx"] = s.get("retransmits", "")
    # flag the esnet/iperf#836 symptom: receiver-side duration differs from sender-side
    row["dur_mismatch"] = "yes" if abs(r["seconds"] - s["seconds"]) > 0.05 * s["seconds"] else "no"
except Exception as ex:
    row.update(gbps_sent="", gbps_recv="", retx="", dur_mismatch=f"parse error: {ex}")

h = mpstat_avg(os.path.join(d, "host_mpstat.txt"))
row["host_kernel_cores"] = round((h.get("%sys", 0) + h.get("%soft", 0) + h.get("%irq", 0)) * hcpu / 100, 2) if h else ""
row["vms_cores"] = round(h.get("%guest", 0) * hcpu / 100, 2) if h else ""
row["vhost_cores"] = round(vhost_cores(os.path.join(d, "host_pidstat.txt")), 2)
v = mpstat_avg(os.path.join(d, "vm2_mpstat.txt"))
row["vm2_busy_pct"] = round(100 - v["%idle"], 2) if v else ""
a = mpstat_avg(os.path.join(d, "arm_mpstat.txt"))
row["arm_busy_pct"] = round(100 - a["%idle"], 2) if a else ""
row["arm_soft_pct"] = a.get("%soft", "") if a else ""
try:
    txt = open(os.path.join(d, "flows_mid.txt")).read()
    flows = [l for l in txt.splitlines() if l.strip() and not l.startswith(("flow-dump", "ovs-"))]
    row["flows_total"], row["flows_offloaded"] = len(flows), txt.count("offloaded:yes")
    row["dp_tags"] = "+".join(sorted(set(re.findall(r"dp:(\w+)", txt)))) or "-"
except OSError:
    row.update(flows_total="", flows_offloaded="", dp_tags="")

new = not os.path.exists(csvp)
with open(csvp, "a", newline="") as fh:
    w = csv.DictWriter(fh, fieldnames=list(row))
    if new: w.writeheader()
    w.writerow(row)
print("  " + "  ".join(f"{k}={v}" for k, v in row.items() if k != "run"))
PY
}

# ---- rounds -----------------------------------------------------------------
for R in $(seq 1 "$ROUNDS"); do
  for P in $PATHS; do run_one "$P" "$R"; sleep 5; done
done
log "done. rows in $OUT/summary.csv"
