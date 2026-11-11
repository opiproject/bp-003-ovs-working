# Validation results — index

Dated results for Blueprint 003, scored against [`../offload-proof-contract.md`](../offload-proof-contract.md). Raw logs sit next to each write-up; nothing here contains credentials.

| Date | Result | Contract status | Summary |
|------|--------|-----------------|---------|
| 2026-09-28 | [Offload proof: OVS-DOCA on BF3](2026-09-28-offload-proof.md) | Items 1, 2, 5 pass · 3 partial · **4 not met** | All flows `dp:doca` + `offloaded:yes`, Arm `%soft` 0.00, 0 retransmits; negative control 5.5 Gbit/s with 305,868 retransmits. Guests on macvtap, not HW vDPA yet |
| 2026-09-28 | [Datapath comparison: software vs TC vs OVS-DOCA](2026-09-28-datapath-comparison.md) | n/a (performance) | ⚠️ **Under revision (#2).** Sender-side totals put TC and OVS-DOCA at parity (28.1 vs 28.8 Gbit/s); the published +13.5 % used `sum_received` and does not hold. Software path 5.5 Gbit/s |
| 2026-10-07 | [VM attach via BF3 virtio-net emulation](2026-10-07-virtio-net-emulation.md) | Items 1, 2, 3 pass · **4 met in intent, wording pending** | Stock `virtio_net` guest on a BF3-emulated device (VFIO), host vhost 0.00 cores (macvtap 1.6–1.8), host kernel CPU per Gbit/s about halved. Emulation 24.9 Gbit/s (TC) / 19.3 (OVS-DOCA) vs macvtap ~28. Lab rolled back 2026-10-08 |
| 2026-10-29 | [Single-queue macvtap on the rebuilt platform](2026-10-29-singlequeue-macvtap.md) | n/a (performance) | sw 12.53, TC 30.72, OVS-DOCA 30.27 Gbit/s (5 rounds). Limit: one host vhost thread at 98.9 %, not the card. Retransmits are real losses at `macvtap` rx |
| 2026-11-09 | [VM attach paths — results summary](2026-11-11-attach-paths-summary.md#bulk-tcp-throughput-median-with-range-gbits) | n/a (performance) | 4-queue macvtap: TC 50.82, OVS-DOCA 55.71. mlx5 VF passthrough: TC 93.61, OVS-DOCA 93.40 (line rate). Step-4 over VFs: latency, CPU at 10 Gbit/s, TCP_CRR, pps |
| 2026-11-11 | [Emulation on virtio VFs + DPF incident](2026-11-11-attach-paths-summary.md#emulation-11-nov--what-the-13-completed-runs-show-and-their-limits) | Item 4: attach off the host (vhost 0.0) | Emulation TC 41.93, OVS-DOCA 46.53 Gbit/s (13 runs), not like-for-like (one e-switch). Session ended when a DPF deployment reset and reprovisioned the card ([evidence](incident-2026-11-11/)) |

Supporting files per date: `<date>/raw/` (harness output), `<date>/EVIDENCE.md` (verbatim excerpts, generated), `<date>/env/` (version pins). From 29 Oct: one folder per session in `sessions/<session>/` (`summary.txt`, `run.log`, `params.txt`, `raw.tar.gz`).
Harness: [`artifacts/scripts/offload-bench/`](../../../artifacts/scripts/offload-bench/).
