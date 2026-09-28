# OVS offload benchmark — run run_20260928T144857Z

iperf3 vm1 -> vm2 (10.99.0.1 -> 10.99.0.2), 60s x 8 streams, via BF3 eswitch + wire.
Arm cores: 16. Timestamps are host (dh5) UTC; the BF3 clock is not trusted.

| Level | Throughput (Gbit/s) | Arm busy % | Arm busy cores | %soft | Retransmits | Flows offloaded (mid-run) | dp |
|---|---|---|---|---|---|---|---|
| L2 Arm kernel datapath (hw-offload=false) | 5.50 | 2.13 | 0.34 | 1.23 | 305868 | 0/6 | ovs |
| L3 kernel + tc eswitch offload | 20.82 | 0.77 | 0.12 | 0.00 | 0 | 10/12 | ovs,tc |

Evidence per level: `<mode>/flows_mid.txt` (dpctl/dump-flows -m), `<mode>/dpif_mid.txt`, `<mode>/mpstat.txt`, `<mode>/iperf.json`, `<mode>/arm_mode.txt` (OVS config used).
