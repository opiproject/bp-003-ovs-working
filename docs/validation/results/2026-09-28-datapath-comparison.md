# Datapath comparison — software vs TC offload vs OVS-DOCA on BF3

**Date:** 2026-09-28 (host UTC) · **Author:** Yash Singh · **Lab:** OPI Lab, host dh5 + BlueField-3 (DPU mode), DOCA 3.5
**Question:** On the same card, topology and traffic, how do the three Arm-side OVS datapaths compare, and does the Blueprint's locked path (OVS-DOCA) hold up against TC offload?
**Harness:** [`artifacts/scripts/offload-bench/`](../../../artifacts/scripts/offload-bench/) · **Raw data:** [`2026-09-28/raw/`](2026-09-28/raw/) · **Offload evidence:** [`2026-09-28-offload-proof.md`](2026-09-28-offload-proof.md)

## Summary

| | L2 software (`sw`) | L3 TC offload (`tc`) | L4 OVS-DOCA (`doca`) |
|---|---|---|---|
| Throughput, paired rounds (mean ± SD, n=3) | — | **25.33 ± 1.11 Gbit/s** | **28.76 ± 1.25 Gbit/s** |
| Throughput, first round | 5.50 Gbit/s | 20.82 Gbit/s | 23.94 Gbit/s |
| TCP retransmits (60 s) | 305,868 | 0–1 | 0 |
| Arm `%soft` | 1.23 | 0.00 | 0.00 |
| Arm cores busy | 0.34 | 0.12 | 1.13 (PMD polling) |
| Flows offloaded | 0 / 6 | all data flows (2 STP control flows excluded) | all flows |

- **Offload in either form beats the soft path by ~4–5×** and removes packet loss entirely (305,868 → 0 retransmits).
- **OVS-DOCA beat TC offload in all 3 paired rounds**, by +3.43 Gbit/s on average (**+13.5 %**, per-round range +6.5 % to +23.5 %). The ranges don't overlap: the best TC round (26.57) is below the worst OVS-DOCA round (27.80).
- **The cost:** OVS-DOCA keeps about one Arm core busy (PMD busy-polling, independent of load). TC offload keeps about 0.12.
- This supports the Blueprint's locked choice of OVS-DOCA over TC as the primary path, with the caveats below.

## Datapaths compared

| Level | Arm OVS configuration | Where packets are switched | Role in the Blueprint |
|-------|----------------------|----------------------------|-----------------------|
| **L2 `sw`** | Kernel datapath, `hw-offload=false` | Arm kernel (every packet) | Negative control |
| **L3 `tc`** | Kernel datapath, `hw-offload=true` | E-switch, via TC-flower rules (`dp:tc`) | Comparison only. Not a primary path per the contract |
| **L4 `doca`** | `doca-init=true`, `hw-offload=true`, `datapath_type=netdev`, `type=dpdk` | E-switch, via DOCA Flow (`dp:doca`) | **Primary path** |

Exact configuration per level: [`2026-09-28-offload-proof.md#offload-parameters`](2026-09-28-offload-proof.md#offload-parameters).

## Setup

Identical for every level; only the Arm OVS configuration changes between measurements.

| Item | Value |
|------|-------|
| Topology | vm1 → host PF0 (macvtap) → BF3 e-switch → `p0` → ToR → `p1` → e-switch → host PF1 (macvtap) → vm2 |
| DPU | BlueField-3, DPU mode, DOCA 3.5 BFB, 16 Arm cores |
| Host | Ubuntu, kernel `6.8.0-139-generic`, DOCA-Host 3.5 |
| Guests | 2 × Ubuntu 22.04, 4 vCPU / 4 GiB, virtio-net on macvtap |
| Traffic | `iperf3 -c 10.99.0.2 -t 60 -P 8` (TCP, 8 streams, 60 s) |
| Arm CPU | `mpstat -P ALL 1` for the full 60 s; the `Average: all` row is reported |
| Flow evidence | `ovs-appctl dpctl/dump-flows -m` at t = 30 s, under load |
| Versions | [`2026-09-28/env/host.txt`](2026-09-28/env/host.txt), [`2026-09-28/env/arm.txt`](2026-09-28/env/arm.txt) |

## Method: why paired rounds

Throughput drifted during the day: the same TC configuration measured 20.82 Gbit/s at 14:50 UTC and 24.42–26.57 Gbit/s after 15:57 UTC. Comparing levels measured at different times would mix that drift into the result. So the TC vs OVS-DOCA comparison uses **paired rounds**: each round runs `tc` then `doca` back-to-back (~3 min apart), and differences are taken within a round.

```bash
for i in 1 2 3; do sudo ARM=<user>@<arm> ./opi_bench.sh tc doca; done
```

## Results

### Paired rounds: TC vs OVS-DOCA

| Round (run, host UTC) | TC Gbit/s | OVS-DOCA Gbit/s | Δ Gbit/s | Δ % | TC retx | DOCA retx | TC flows off. | DOCA flows off. |
|---|---|---|---|---|---|---|---|---|
| 1 (`20260928T155730Z`) | 24.42 | 30.17 | +5.75 | +23.5 % | 1 | 0 | 8/10 | 10/10 |
| 2 (`20260928T160023Z`) | 24.99 | 27.80 | +2.81 | +11.2 % | 0 | 0 | 4/6 | 6/6 |
| 3 (`20260928T160315Z`) | 26.57 | 28.30 | +1.73 | +6.5 % | 0 | 0 | 4/6 | 6/6 |
| **Mean ± SD** | **25.33 ± 1.11** | **28.76 ± 1.25** | **+3.43 ± 2.08** | **+13.5 %** | | | | |
| Min – max | 24.42 – 26.57 | 27.80 – 30.17 | +1.73 – +5.75 | | | | | |

The 2 non-offloaded flows in each TC run are the switch's spanning-tree frames (`dst=01:80:c2:00:00:00`, `actions:drop`); see [`EVIDENCE.md`](2026-09-28/EVIDENCE.md). All test-traffic flows were offloaded at both levels.

### Arm CPU per level

| Level | Arm busy (avg, 16 cores) | ≈ Cores | `%soft` | Hottest core | Nature of the cost |
|-------|--------------------------|---------|---------|--------------|--------------------|
| `sw` | 2.13 % | 0.34 | 1.23 | core 5: 6.75 % soft, 92.7 % idle | Per-packet softirq, yet not CPU-bound: loss happens before the CPU saturates |
| `tc` | 0.75–0.77 % | 0.12 | 0.00 | — | Control-plane only |
| `doca` | 7.05–7.15 % | 1.13 | 0.00 | core 11 (PMD) | One PMD thread busy-polling; fixed, not per-packet |

### All levels, first round (not paired)

For the software baseline, which was run once:

| Run | Level | Gbit/s | Retransmits | Arm busy | `%soft` | Flows offloaded |
|-----|-------|--------|-------------|----------|---------|-----------------|
| `20260928T144857Z` | `sw` | 5.50 | 305,868 | 2.13 % | 1.23 | 0/6 (`dp:ovs`) |
| `20260928T144857Z` | `tc` | 20.82 | 0 | 0.77 % | 0.00 | 10/12 (2 STP) |
| `20260928T150444Z` | `doca` | 23.94 | 0 | 7.06 % | 0.00 | 6/6 (`dp:doca`) |

### Reference: previous image (DOCA 2.6 BFB, 2026-08-27)

Same topology and harness design, before the card was reimaged to DOCA 3.5. It isn't paired with today's runs, so treat it as context only.

| Level | Gbit/s | Retransmits | Arm busy | Flows offloaded |
|-------|--------|-------------|----------|-----------------|
| `sw` | 20.83 | 27,604 | 5.42 % | 0/4 (`dp:ovs`) |
| `tc` | 22.67 | 0 | 0.29 % | 4/4 (`dp:tc`) |
| `doca` | not available on that image | | | |

Raw data: `2026-09-28/raw/run_20260827T060721Z/`. The TC result is consistent across images. The software path was much worse on DOCA 3.5 (5.50 vs 20.83 Gbit/s, 10× the retransmits); the cause is not investigated, and it doesn't affect the offloaded results.

## Interpretation

1. **Hardware offload is the difference between a lossy and a clean datapath.** Moving switching into the e-switch (either TC or DOCA) removes all retransmits and raises throughput 3.8–5.5×.
2. **OVS-DOCA is faster than TC offload here** (+13.5 % mean, consistent across 3 paired rounds), and it is the path NVIDIA documents for OVS on BlueField and the one the Blueprint has locked.
3. **OVS-DOCA's CPU cost is a reserved core, not a scaling cost.** The PMD thread polls continuously, so in capacity planning it is ~1 Arm core per PMD, flat.
4. **Absolute numbers are probably limited by the guest attach, not the e-switch.** Every packet still goes through the host kernel (virtio → vhost-net → macvtap → PF), and nothing in these runs shows the e-switch as the bottleneck: Arm `%soft` is 0 and there are no retransmits. This is a hypothesis to confirm with the HW vDPA runs, not a measured result. The comparison between levels is valid because the attach is the same for all of them; the absolute throughput is not a statement about BF3 capacity.

## Limitations

| Limitation | Effect |
|------------|--------|
| n = 3 paired rounds | Enough to show a consistent direction, not a tight effect size (per-round Δ ranges 6.5–23.5 %) |
| Software baseline run once on DOCA 3.5 | L2 figures are indicative |
| TCP bulk, 8 streams, default MTU | No packet-rate / small-packet / latency data |
| macvtap attach (host kernel in path) | Caps absolute throughput; contract item 4 (HW vDPA) not yet exercised |
| One card, one topology, one host | No multi-tenant, VF, or scale-out results |
| Arm clock unsynchronised (no NTP on BFB) | All timestamps are host UTC |

## Next measurements

1. Repeat L2 vs L4 with the **HW vDPA + vhost-user** attach (contract item 4); expect higher absolute throughput and lower host CPU.
2. Add host CPU (not just Arm CPU) to the harness, since that is what HW vDPA should reduce.
3. Capture `dpctl/offload-stats-show` (already added to the harness) and pps with small packets.
4. Re-run the software baseline 3× to firm up L2 on DOCA 3.5.
