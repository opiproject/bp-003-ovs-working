#!/usr/bin/env bash
# opi_bench.sh — run the offload benchmark FROM HOST dh5.
# Usage:  sudo ARM=ubuntu@<bf3-arm-ip> ./opi_bench.sh sw tc [doca]
#   modes: sw = Arm kernel datapath, hw-offload=false (negative control)
#          tc = Arm kernel datapath + TC offload (comparison only)
#          doca = OVS-DOCA datapath (contract primary path)
#   each mode: switch the Arm OVS (via opi_arm_mode.sh), run iperf3 vm1->vm2,
#   sample Arm CPU (mpstat) for the whole run and datapath flows mid-run.
# Output: /opt/opi_experiment/metrics/run_<ts>/<mode>/ + one REPORT.md per run.
# After the run the Arm is put back in $RESTORE mode (default: tc, the original state).
set -euo pipefail

ARM="${ARM:?set ARM=<user>@<bf3-arm-mgmt-ip>}"
DUR="${DUR:-60}"; STREAMS="${STREAMS:-8}"
RESTORE="${RESTORE:-tc}"
KEY=/root/.ssh/id_ed25519
VMENV=/opt/opi_experiment/vms/vms.env
SSHV=(-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i "$KEY")
SSHA=(-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8)

[[ $# -ge 1 ]] || { echo "usage: $0 sw tc [doca]"; exit 2; }
[[ -f $VMENV ]] || { echo "no $VMENV — run opi_host_vms.sh setup first"; exit 1; }
# shellcheck disable=SC1090
source "$VMENV"

TS=$(date -u +%Y%m%dT%H%M%SZ)          # host clock (the Arm clock is wrong)
RUN=/opt/opi_experiment/metrics/run_$TS
mkdir -p "$RUN"
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$RUN/run.log"; }
vm()  { local ip=$1; shift; ssh "${SSHV[@]}" ubuntu@"$ip" "$@"; }
arm() { ssh "${SSHA[@]}" "$ARM" "$@"; }

log "preflight"
arm 'sudo -n /usr/local/sbin/opi_arm_mode.sh status' > "$RUN/arm_status_initial.txt" \
  || { log "cannot drive the Arm (ssh key or sudoers?) — see runbook step 2"; exit 1; }
arm 'command -v mpstat >/dev/null' || { log "mpstat missing on Arm"; exit 1; }
ARM_CPUS=$(arm nproc)
vm "$VM1_IP" 'ping -c 2 -W 2 10.99.0.2 >/dev/null' || { log "vm1 cannot reach 10.99.0.2"; exit 1; }

for MODE in "$@"; do
  D="$RUN/$MODE"; mkdir -p "$D"
  log "=== $MODE: switching Arm OVS"
  arm "sudo -n /usr/local/sbin/opi_arm_mode.sh $MODE" > "$D/arm_mode.txt" 2>&1
  sleep 5
  vm "$VM1_IP" 'ping -c 3 -W 2 10.99.0.2 >/dev/null' || { log "$MODE: datapath down after switch — see $D/arm_mode.txt"; continue; }

  vm "$VM2_IP" 'pkill -x iperf3 || true; iperf3 -s -D'
  sleep 1
  log "$MODE: iperf3 ${DUR}s x $STREAMS streams"
  arm "mpstat -P ALL 1 $DUR" > "$D/mpstat.txt" 2>&1 &
  MP=$!
  vm "$VM1_IP" "iperf3 -c 10.99.0.2 -t $DUR -P $STREAMS -J" > "$D/iperf.json" &
  IP=$!
  sleep $((DUR / 2))
  arm 'sudo -n ovs-appctl dpctl/dump-flows -m' > "$D/flows_mid.txt" 2>&1 || true
  arm 'sudo -n ovs-appctl dpif/show'           > "$D/dpif_mid.txt"  2>&1 || true
  arm 'sudo -n ovs-appctl dpctl/offload-stats-show' > "$D/offload_stats_mid.txt" 2>&1 || true
  wait $IP || log "$MODE: iperf3 exited non-zero"
  arm 'sudo -n ovs-vsctl get Open_vSwitch . other_config; sudo -n ovs-vsctl show' > "$D/ovs_config.txt" 2>&1 || true
  wait $MP || true
  vm "$VM2_IP" 'pkill -x iperf3 || true'
done

log "restoring Arm to $RESTORE"
arm "sudo -n /usr/local/sbin/opi_arm_mode.sh $RESTORE" > "$RUN/arm_restore.txt" 2>&1 || log "restore failed — check Arm"

python3 - "$RUN" "$ARM_CPUS" "$DUR" "$STREAMS" "$@" <<'PY'
import json, re, sys, os
run, ncpu, dur, streams, modes = sys.argv[1], int(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5:]
label = {"sw": "L2 Arm kernel datapath (hw-offload=false)",
         "tc": "L3 kernel + tc eswitch offload",
         "doca": "L4 OVS-DOCA offload"}
rows = []
for m in modes:
    d = os.path.join(run, m); r = {"mode": m}
    try:
        j = json.load(open(os.path.join(d, "iperf.json")))
        r["gbps"] = j["end"]["sum_received"]["bits_per_second"] / 1e9
        r["retx"] = j["end"]["sum_sent"].get("retransmits", "n/a")
    except Exception as e:
        r["gbps"], r["retx"] = None, f"parse error: {e}"
    busy = soft = None
    try:
        hdr = None
        for line in open(os.path.join(d, "mpstat.txt")):
            f = line.split()
            if len(f) > 2 and f[0] == "Average:" and f[1] == "CPU":
                hdr = f
            elif hdr and len(f) > 2 and f[0] == "Average:" and f[1] == "all":
                idle = float(f[hdr.index("%idle")]); soft = float(f[hdr.index("%soft")])
                busy = 100 - idle
    except Exception:
        pass
    r["busy"], r["soft"] = busy, soft
    try:
        txt = open(os.path.join(d, "flows_mid.txt")).read()
        flows = [l for l in txt.splitlines() if l.strip() and not l.startswith(("flow-dump", "ovs-"))]
        r["flows"] = len(flows)
        r["off"] = txt.count("offloaded:yes")
        r["dp"] = ",".join(sorted(set(re.findall(r"dp:(\w+)", txt)))) or "-"
    except Exception:
        r["flows"], r["off"], r["dp"] = 0, 0, "-"
    rows.append(r)

def f(v, fmt):
    return fmt.format(v) if isinstance(v, (int, float)) else str(v)

out = [f"# OVS offload benchmark — run {os.path.basename(run)}", "",
       f"iperf3 vm1 -> vm2 (10.99.0.1 -> 10.99.0.2), {dur}s x {streams} streams, via BF3 eswitch + wire.",
       f"Arm cores: {ncpu}. Timestamps are host (dh5) UTC; the BF3 clock is not trusted.", "",
       "| Level | Throughput (Gbit/s) | Arm busy % | Arm busy cores | %soft | Retransmits | Flows offloaded (mid-run) | dp |",
       "|---|---|---|---|---|---|---|---|"]
for r in rows:
    cores = r["busy"] * ncpu / 100 if isinstance(r["busy"], float) else None
    out.append(f"| {label.get(r['mode'], r['mode'])} | {f(r['gbps'],'{:.2f}')} | {f(r['busy'],'{:.2f}')} | "
               f"{f(cores,'{:.2f}')} | {f(r['soft'],'{:.2f}')} | {r['retx']} | {r['off']}/{r['flows']} | {r['dp']} |")
out += ["", "Evidence per level: `<mode>/flows_mid.txt` (dpctl/dump-flows -m), `<mode>/dpif_mid.txt`, "
        "`<mode>/offload_stats_mid.txt`, `<mode>/mpstat.txt`, `<mode>/iperf.json`, `<mode>/ovs_config.txt`."]
open(os.path.join(run, "REPORT.md"), "w").write("\n".join(out) + "\n")
print("\n".join(out))
PY
log "report: $RUN/REPORT.md"
