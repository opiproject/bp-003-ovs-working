#!/usr/bin/env bash
# ~/bench/pg_guest.sh — runs INSIDE vm1 as root (the suite copies it to /tmp/pg.sh)
# usage: pg_guest.sh IFACE DST_MAC SRC_IP DST_IP PKT_SIZE SECS THREADS
# Kernel pktgen UDP stream, one thread per tx queue; prints tx counter samples.
IF=$1 DMAC=$2 SIP=$3 DIP=$4 SZ=$5 SECS=$6 TH=$7
PG=/proc/net/pktgen
modprobe pktgen || exit 1
echo reset > $PG/pgctrl
for t in $(seq 0 $((TH - 1))); do
  echo rem_device_all > $PG/kpktgend_$t
  echo "add_device $IF@$t" > $PG/kpktgend_$t
  D=$PG/$IF@$t
  for c in "count 0" "pkt_size $SZ" "delay 0" "dst $DIP" "dst_mac $DMAC" \
           "src_min $SIP" "src_max $SIP" "udp_dst_min 9" "udp_dst_max 9" \
           "udp_src_min 10000" "udp_src_max 10999" "flag UDPSRC_RND" \
           "queue_map_min $t" "queue_map_max $t"; do
    echo "$c" > $D || echo "pktgen rejected: $c"
  done
  echo "clone_skb 1000" > $D 2>/dev/null || echo "clone_skb 0" > $D
  echo "burst 32" > $D 2>/dev/null || echo "burst not supported, using 1"
done
cnt() { echo "$(date +%s.%N) $(cat /sys/class/net/$IF/statistics/tx_packets)"; }
echo start > $PG/pgctrl &
S=$!
sleep 2;               echo "tx_a $(cnt)"
sleep $((SECS - 5));   echo "tx_b $(cnt)"
echo stop > $PG/pgctrl
wait $S 2>/dev/null
for t in $(seq 0 $((TH - 1))); do grep -h -A1 "^Result" $PG/$IF@$t 2>/dev/null; done
