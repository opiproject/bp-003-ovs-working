#!/usr/bin/env bash
# ~/bench/bench_bulk.sh — bulk TCP in paired rounds across Arm datapaths
# usage: ROUNDS=5 DUR=60 ./bench_bulk.sh sw tc doca
set -uo pipefail
source ~/bench/lib.sh
ROUNDS=${ROUNDS:-5}; DUR=${DUR:-60}; STREAMS=${STREAMS:-8}
MODES=("$@"); [ ${#MODES[@]} -gt 0 ] || { echo "usage: $0 sw tc doca"; exit 2; }
RUN=~/bench/results/bulk_$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$RUN"
for r in $(seq 1 "$ROUNDS"); do
  ORDER=("${MODES[@]}"); (( r % 2 == 0 )) && ORDER=($(printf '%s\n' "${MODES[@]}" | tac))
  for m in "${ORDER[@]}"; do
    D="$RUN/r${r}_$m"; mkdir -p "$D"
    log "round $r: switching Arm to $m"
    { echo "vswitchd pid before: $(arm pidof ovs-vswitchd)"
      arm "sudo -n /usr/local/sbin/opi_arm_mode.sh $m"
      echo "vswitchd pid after: $(arm pidof ovs-vswitchd)"; } > "$D/arm_mode.txt" 2>&1 \
      || { log "mode switch failed, see $D/arm_mode.txt"; exit 1; }
    sleep 5
    vm1 "ping -c 3 -W 2 $DST" > /dev/null || { log "$m: vm1 cannot reach $DST"; exit 1; }
    meta "$D" "$m"; snap "$D" before
    vm2 'pkill -x iperf3; iperf3 -s -D'; sleep 1
    mpstat -P ALL 1 "$DUR" > "$D/host_mpstat.txt" &  P1=$!
    pidstat -t -u 1 "$DUR" > "$D/host_pidstat.txt" & P2=$!
    vm1 "mpstat -P ALL 1 $DUR" > "$D/vm1_mpstat.txt" & P3=$!
    vm2 "mpstat -P ALL 1 $DUR" > "$D/vm2_mpstat.txt" & P4=$!
    arm "mpstat -P ALL 1 $DUR" > "$D/arm_mpstat.txt" & P5=$!
    vm1 "iperf3 -c $DST -t $DUR -P $STREAMS -J" > "$D/iperf.json" & P6=$!
    sleep $((DUR / 2))
    arm 'sudo -n ovs-appctl dpctl/dump-flows -m' > "$D/flows_mid.txt" 2>&1
    arm 'sudo -n ovs-appctl dpif/show; sudo -n ovs-appctl dpif-doca/pmd-stats-show 2>/dev/null || sudo -n ovs-appctl dpif-netdev/pmd-stats-show' > "$D/dpif_mid.txt" 2>&1
    wait $P6 $P1 $P2 $P3 $P4 $P5
    snap "$D" after
    vm2 'pkill -x iperf3'
    log "$m done: $(python3 -c "import json;e=json.load(open('$D/iperf.json'))['end']['sum_sent'];print('%.2f Gbit/s sent, %s retransmits'%(e['bits_per_second']/1e9,e['retransmits']))" 2>&1)"
  done
done
arm 'sudo -n /usr/local/sbin/opi_arm_mode.sh tc' > "$RUN/arm_restore.txt" 2>&1
log "finished; Arm restored to tc; results in $RUN"
