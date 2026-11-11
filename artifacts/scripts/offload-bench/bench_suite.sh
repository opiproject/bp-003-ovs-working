#!/usr/bin/env bash
# ~/bench/bench_suite.sh — step 4: CPU at a fixed rate, latency (idle and loaded),
# packet rate (pktgen), connection rate (TCP_CRR), in paired rounds across Arm datapaths.
# usage: DST=10.99.1.2 TNIC=vf0 ROUNDS=3 ./bench_suite.sh sw tc doca
set -uo pipefail
source ~/bench/lib.sh
ROUNDS=${ROUNDS:-3}; T=${T:-30}; FIXED_T=${FIXED_T:-60}; PKT_T=${PKT_T:-20}
STREAMS=${STREAMS:-8}; RATE_PER=${RATE_PER:-1250M}        # 8 x 1.25 Gbit/s = 10 Gbit/s
SIZES=${SIZES:-"64 512 1500"}; PG_THREADS=${PG_THREADS:-4}
MODES=("$@"); [ ${#MODES[@]} -gt 0 ] || { echo "usage: $0 sw tc doca"; exit 2; }
RUN=~/bench/results/suite_$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$RUN"

mon() {  # mon <dir> <secs>: CPU sampling on host, both guests and the Arm; pids in MON
  local d=$1 s=$2
  mpstat -P ALL 1 "$s" > "$d/host_mpstat.txt" &  MON="$!"
  pidstat -t -u 1 "$s" > "$d/host_pidstat.txt" & MON="$MON $!"
  vm1 "mpstat -P ALL 1 $s" > "$d/vm1_mpstat.txt" & MON="$MON $!"
  vm2 "mpstat -P ALL 1 $s" > "$d/vm2_mpstat.txt" & MON="$MON $!"
  arm "mpstat -P ALL 1 $s" > "$d/arm_mpstat.txt" & MON="$MON $!"
}
NP() { echo "netperf -H $DST -l $T -t $1 -- -r 1,1 -k THROUGHPUT,THROUGHPUT_UNITS,MEAN_LATENCY,P50_LATENCY,P90_LATENCY,P99_LATENCY"; }
RX() { vm2 "echo $1 \$(date +%s.%N) \$(cat /sys/class/net/$TNIC/statistics/rx_packets) \$(cat /sys/class/net/$TNIC/statistics/rx_dropped)"; }

# one-time guest preparation (non-persistent)
SIP=$(vm1 "ip -4 -o addr show $TNIC | awk '{print \$4}' | cut -d/ -f1")
DMAC=$(vm2 "cat /sys/class/net/$TNIC/address")
[ -n "$SIP" ] && [ -n "$DMAC" ] || { log "cannot read $TNIC address/MAC in the guests"; exit 1; }
vm1 "cat > /tmp/pg.sh" < ~/bench/pg_guest.sh
vm1 "sudo modprobe pktgen 2>/dev/null || { sudo apt-get install -y -qq linux-modules-extra-\$(uname -r) >/dev/null && sudo modprobe pktgen; }; test -d /proc/net/pktgen" \
  || { log "pktgen not available in vm1"; exit 1; }
vm1 "sudo sysctl -qw net.ipv4.tcp_tw_reuse=1 net.ipv4.ip_local_port_range='1024 65000'"
echo "DST=$DST TNIC=$TNIC SIP=$SIP DMAC=$DMAC ROUNDS=$ROUNDS T=$T FIXED_T=$FIXED_T PKT_T=$PKT_T RATE=${STREAMS}x$RATE_PER SIZES=$SIZES PG_THREADS=$PG_THREADS vm1:tw_reuse=1,ports=1024-65000" | tee "$RUN/params.txt"

for r in $(seq 1 "$ROUNDS"); do
  ORDER=("${MODES[@]}"); (( r % 2 == 0 )) && ORDER=($(printf '%s\n' "${MODES[@]}" | tac))
  for m in "${ORDER[@]}"; do
    D="$RUN/r${r}_$m"; mkdir -p "$D"
    log "round $r: switching Arm to $m"
    arm "sudo -n /usr/local/sbin/opi_arm_mode.sh $m" > "$D/arm_mode.txt" 2>&1 \
      || { log "mode switch failed, see $D/arm_mode.txt"; exit 1; }
    sleep 5
    vm1 "ping -c 3 -W 2 $DST" > /dev/null || { log "$m: vm1 cannot reach $DST"; exit 1; }
    vm2 "pkill -x iperf3; iperf3 -s -D; pgrep -x netserver >/dev/null || netserver" > /dev/null 2>&1
    meta "$D" "$m"; snap "$D" before

    # 1. CPU at a fixed rate (10 Gbit/s total)
    mkdir -p "$D/fixed"; mon "$D/fixed" "$FIXED_T"
    vm1 "iperf3 -c $DST -t $FIXED_T -P $STREAMS -b $RATE_PER -J" > "$D/fixed/iperf.json" & P=$!
    sleep $((FIXED_T / 2)); arm 'sudo -n ovs-appctl dpctl/dump-flows -m' > "$D/fixed/flows_mid.txt" 2>&1
    wait $P $MON

    # 2. latency, idle (1-byte request/response)
    mkdir -p "$D/rr_idle"; mon "$D/rr_idle" "$T"
    vm1 "$(NP TCP_RR)" > "$D/rr_idle/netperf.txt" 2>&1; wait $MON

    # 3. latency under the 10 Gbit/s load
    mkdir -p "$D/rr_load"; mon "$D/rr_load" "$T"
    vm1 "iperf3 -c $DST -t $((T + 4)) -P $STREAMS -b $RATE_PER -J" > "$D/rr_load/iperf.json" & P=$!
    sleep 2; vm1 "$(NP TCP_RR)" > "$D/rr_load/netperf.txt" 2>&1; wait $P $MON

    # 4. packet rate (pktgen UDP; size = frame incl. 4-byte FCS)
    for s in $SIZES; do
      mkdir -p "$D/pps_$s"; mon "$D/pps_$s" "$PKT_T"
      vm1 "sudo bash /tmp/pg.sh $TNIC $DMAC $SIP $DST $((s - 4)) $PKT_T $PG_THREADS" > "$D/pps_$s/pktgen.txt" 2>&1 & P=$!
      sleep 2; RX rx_a > "$D/pps_$s/rx.txt"
      sleep $((PKT_T - 5)); RX rx_b >> "$D/pps_$s/rx.txt"
      wait $P $MON; sleep 2
    done

    # 5. connection rate (new TCP connection per transaction)
    mkdir -p "$D/crr"; mon "$D/crr" "$T"
    vm1 "$(NP TCP_CRR)" > "$D/crr/netperf.txt" 2>&1 & P=$!
    sleep $((T / 2)); arm 'sudo -n ovs-appctl dpctl/dump-flows -m' > "$D/crr/flows_mid.txt" 2>&1
    wait $P $MON

    snap "$D" after
    vm2 'pkill -x iperf3' > /dev/null 2>&1
    log "$m round $r done: $(python3 ~/bench/summarize_suite.py "$D" --one 2>&1 | tail -1)"
  done
done
arm 'sudo -n /usr/local/sbin/opi_arm_mode.sh tc' > "$RUN/arm_restore.txt" 2>&1
log "finished; Arm restored to tc; results in $RUN"
