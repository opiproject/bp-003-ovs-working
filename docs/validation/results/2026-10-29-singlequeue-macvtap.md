# 29 Oct 2026 — single-queue macvtap, three Arm datapaths

## Setup
- Host dh5: Ubuntu 22.04.5, kernel 6.8.0-138-generic (HWE), DOCA-Host 3.5 (mlx5_core 2607.0.100 from updates/dkms).
- BF3: BFB bf-bundle-3.5.0-89_26.07, OVS 3.5.0052. p0/p1 at 100 Gb/s, MTU 1500, hairpin p0 → Arista A100G → p1.
- Guests: Ubuntu 24.04 cloud image, 4 vCPU, 4 GiB, iperf3 3.16, memory on NUMA node 0.
  vm1 vCPUs 2,4,6,8 (emulator 18,20); vm2 vCPUs 10,12,14,16 (emulator 22,24).
  Test NIC: macvtap bridge mode on the PF, virtio-net, **one queue** (virt-install default).
- CPU governor: performance. Harness: lib.sh + bench_bulk.sh + summarize.py (this folder).
- Method: 5 rounds, mode order alternates each round (sw-tc-doca, doca-tc-sw, …), iperf3 8 streams × 60 s,
  throughput from the **sender** side, steady state excludes the first 5 s.

## Results (sender side, steady state)
| Mode | Median Gbit/s | Range | Median retransmits | Flows offloaded | Arm cores busy |
|---|---|---|---|---|---|
| sw (hw-offload=false) | 12.53 | 12.38–12.62 | 492,339 | 0 (dp:ovs) | ~0.94–1.03 (one core 70–75% softirq) |
| tc | 30.72 | 30.22–31.15 | 4,067 | all but 2 STP frames (dp:tc) | ~0.07–0.17 |
| doca | 30.27 | 29.81–30.96 | 5,356 | all (dp:doca) | ~1.12–1.16 (PMD core 11 at 100%) |

Per-second variation (cv) was 1.0–3.1% in every run. Full per-run output: `summary_output_2026-10-29.txt`.

## Diagnosis (run r5_tc; raw output in `diagnosis_r5_tc_2026-10-29.txt`)
- **Ceiling = vm2's single vhost thread.** Two vhost threads: 98.92% and 77.53% of a core (all kernel time).
  Host CPU 22 (vm2 emulator pin) at 98.78% %sys while CPU 24 is 99.98% idle.
- **Guest not saturated.** vm2's busiest vCPU (1): 48.11% softirq, 41.20% idle; the other vCPUs mostly idle.
- Host CPU 12 (vm2 vCPU 1) = 62.65% %guest + 37.08% %sys (inferred: KVM halt polling).
- **Retransmits are real losses, not spurious.** vm1 TcpRetransSegs +4,067; TCPDSACKRecv, TCPTimeouts,
  TCPLossProbes and all reorder counters unchanged. vm2 TCPRcvQDrop and TCPBacklogDrop = 0.
- **Losses happen at macvtap1** (vm2's attach): rx_dropped +95 in this run; 95 dropped ~64 KB GRO blocks
  × ~43 segments ≈ 4,085 ≈ 4,067 retransmits. Across offload runs the ratio is 40–71 segments per drop
  (one outlier at 188).

## Conclusions
- Offload vs software path: ~2.4× throughput, ~100× fewer retransmits.
- TC and OVS-DOCA give equal throughput through this attach; they differ in Arm cost (~0.1 vs ~1.1 cores).
- Through single-queue macvtap, the ~30 Gbit/s ceiling is one host vhost thread, not the card.
  Not proven: that the card can carry 100 Gbit/s (that is the link rate only).

## Next
Recreate the test NICs with 4 queues (`driver.queues=4`, emulator pins 18,20,22,24 and 26,28,30,32) and rerun.
Prediction: throughput well above 30 Gbit/s and fewer macvtap drops. If not, the vhost explanation is wrong.

Note: raw per-run files (mpstat, pidstat, iperf.json, counter snapshots, flow dumps) are on dh5 in
`~/bench/results/bulk_<ts>/`. Copy them into the repo; they are the evidence behind this page.
