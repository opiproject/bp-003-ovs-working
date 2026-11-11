# BP-003 — VM attach paths on BlueField-3: results summary (29 Oct – 11 Nov 2026)

This page summarises the bulk-TCP results for the three VM attach paths measured on dh5
(single- and multi-queue macvtap, mlx5 VF passthrough, virtio-net emulation), the step-4 tests
over VFs, and the incident that ended the emulation session on 11 Nov.
Raw data for every session is in `sessions/<session>/raw.tar.gz`, next to its `summary.txt`.

## Platform

The host is dh5 (Dell R760xa, 2 × Xeon Gold 6526Y) running Ubuntu 22.04.5 with kernel
6.8.0-138-generic and DOCA-Host 3.5 (mlx5_core 2607.0.100). The BlueField-3 (B3220) runs BFB
3.5.0-89 with OVS 3.5.0052 on its Arm. Both VMs are Ubuntu 24.04 with 4 pinned vCPUs on NUMA
node 0 (the card's node). Traffic goes from vm1 to vm2 at MTU 1500. The Arm datapath is switched
between `sw` (kernel OVS, no offload), `tc` (kernel OVS with TC hardware offload) and `doca`
(OVS-DOCA). Bulk tests use iperf3 3.16, 8 streams, 60 s, sender-side totals, in rounds that
alternate the mode order.

## Bulk TCP throughput (median, with range, Gbit/s)

| Attach path | sw | tc | doca | Session |
|---|---|---|---|---|
| macvtap, 1 queue (29 Oct, n=5) | 12.53 (12.38–12.62) | 30.72 (30.22–31.15) | 30.27 (29.81–30.96) | bulk 29 Oct |
| macvtap, 4 queues (9 Nov, n=5) | 12.76 (12.22–12.92) | 50.82 (44.68–54.17) | 55.71 (45.90–58.74) | `bulk_20261109T110103Z` |
| mlx5 VF passthrough (9 Nov, n=5) | 14.05 (13.98–14.30) | 93.61 (93.03–94.02) | 93.40 (93.30–93.80) | `bulk_20261109T113540Z` |
| virtio-net emulation, VFs (11 Nov) | 16.62 (16.49–16.81), n=5 | 41.93 (28.91–45.94), n=4 | 46.53 (46.25–47.08), n=4 | `bulk_20261111T153703Z` |

**What limits each path.**
With single-queue macvtap, one host vhost thread ran at 98.9 % and capped throughput at about
30 Gbit/s. Four queues raised the offloaded modes by 65–85 %, but the busiest queue's vhost
thread still reached about 99 %, because the 8 streams hash unevenly over the 4 queues; this also
explains the wider spread between runs. Through mlx5 VFs both offloaded modes reach about
93.5 Gbit/s, which is line rate: at MTU 1500 a 100 Gbit/s link carries at most about
94.1 Gbit/s of TCP payload (1448 of every 1538 bytes on the wire). In `sw` mode every path stays
between 12 and 17 Gbit/s, because the Arm forwards in software and one Arm core is saturated by
softirq work.

**Offload works and costs the Arm almost nothing in tc.** In every offloaded run the flow dumps
show the test flows offloaded (`dp:tc` or `dp:doca`). In tc mode the Arm uses 0.1–0.2 cores; in
doca mode it uses a constant ~1.1 cores because the OVS-DOCA PMD core polls at 100 %.

**tc against doca.** Through macvtap and VFs the two modes give the same bulk throughput within
their ranges. Bulk TCP cannot separate them; the fixed-rate tests below can.

## Emulation (11 Nov) — what the 13 completed runs show, and their limits

Two virtio-net VFs were created on one static virtio PF and passed to the VMs through vfio-pci;
the host ran no vhost thread for this traffic. Emulation reached 41.9 Gbit/s (tc) and
46.5 Gbit/s (doca), below 4-queue macvtap and about half of mlx5 VF passthrough.
These numbers come with four limits that must be stated with them:

1. The static PF sits on port 0, so both VMs' VFs are on the same e-switch and traffic never
   crosses the Arista, while the macvtap and VF tests go p0 → Arista → p1. The paths are
   therefore not like-for-like; a fair comparison needs the second BF3 (cross-host).
2. The emulation controller (v26.07.10) offers send-side TSO (`HOST_TSO4/6`) but no receive-side
   TSO (`GUEST_TSO4/6`), so the receiving guest handles every segment. This is the most likely
   reason for the lower throughput [inferred, not measured].
3. Retransmits are very high: about 2 million per run in tc and doca, against a few thousand
   through macvtap and 130–700 thousand through VFs. Where these losses happen was not
   diagnosed.
4. Only 4 runs per offloaded mode completed (one tc run is an outlier at 28.9 Gbit/s); the step-4
   suite was not run on emulation because of the incident below.

**Host CPU per attach path (tc mode, medians).** With 4-queue macvtap the host spends 2.7–3.8 cores on
vhost threads for ~51 Gbit/s. Through mlx5 VFs and through emulation the host spends **0.0 cores on
vhost**: the attach is fully off the host. The remaining host CPU (~6.5–8.3 cores in both cases) is the
guests' own vCPU time, which the host accounts as busy. In emulation the receiving guest's busiest core
was only 62–68 % busy (it was 92–97 % through VFs), so emulation is not limited by guest CPU; with ~2
million retransmits per run it is most likely limited by packet loss [inferred].

## Step-4 tests over mlx5 VFs (9 Nov, 3 rounds per mode, medians)

At a fixed 10 Gbit/s load the Arm uses 0.13 cores in tc, 1.15 in doca and 0.64 in sw, and the
host kernel uses 0.06, 0.08 and 2.66 cores. Idle request/response latency (TCP_RR, 1 byte) is
23/30 µs p50/p99 in tc, 22/29 µs in doca and 47/58 µs in sw. Under the 10 Gbit/s load, p99 is
135 µs in tc and 124 µs in doca (ranges 130–137 and 124–126, so doca is slightly better), while
sw collapses to about 201 ms p99 and 380 transactions/s. Connection rate (TCP_CRR) is 10,978/s
in tc, 11,062/s in doca and 5,225/s in sw; the flows match on MAC only, so this mostly measures
the guest TCP stack, not flow setup. Packet rate: in sw the Arm forwards about 0.75 Mpps at any
frame size; in tc and doca vm2 receives 3.4–3.8 Mpps, which is the receiving guest's limit, not
the card's (the sender reached line rate at 512 and 1500 bytes).
Known measurement issue: iperf3 3.16's `-b` pacing kept vm1 at 4 busy cores at any rate, so the
sender-side CPU in the fixed-rate test is not meaningful; host, receiver and Arm CPU are.

## Incident on 11 Nov: the card was taken over by a DPF deployment

At 15:54:53 UTC, 59 s into the 14th emulation run, both host PFs logged mlx5
`Fatal error 3 detected` and the card reset. The host system log shows the cause:
a `DPFOperatorConfig` was applied to the k3s cluster running on dh5 at 15:54:03
(`quota admission added evaluator for: dpfoperatorconfigs.operator.dpu.nvidia.com`), and
DPF's `static-cm-controller-manager` pod started at 15:54:05. DPF then provisioned the DPU as
`dh5-bluefield-3`: it installed its own BFB twice (the second run at 16:59, through DMS →
`bfb-install`), replaced the card's firmware configuration (virtio-net emulation disabled,
`NUM_OF_VFS=46`, `PF_TOTAL_SF=0`) and rebooted the dh5 host at about 17:30. The 13 runs before
the fatal error completed normally. The logs are in `state/crash_20261111` on dh5.
The DPF owner has been asked to confirm the reset and whether dh5 should stay under DPF.

## Open items

- Emulation on a like-for-like topology, after dh5 is released from DPF (short demo run only).
- Locate the emulation retransmits; test with receive-side TSO if the controller can offer it.
- Fixed-rate sender CPU: pace with `--fq-rate` instead of `-b`.
- Step-4 tests on macvtap and emulation; conntrack-scale test (4b).
