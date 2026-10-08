# Validation results — index

Dated results for Blueprint 003, scored against [`../offload-proof-contract.md`](../offload-proof-contract.md). Raw logs sit next to each write-up; nothing here contains credentials.

| Date | Result | Contract status | Summary |
|------|--------|-----------------|---------|
| 2026-09-28 | [Offload proof: OVS-DOCA on BF3](2026-09-28-offload-proof.md) | Items 1, 2, 5 pass · 3 partial · **4 not met** | All flows `dp:doca` + `offloaded:yes`, Arm `%soft` 0.00, 0 retransmits; negative control 5.5 Gbit/s with 305,868 retransmits. Guests on macvtap, not HW vDPA yet |
| 2026-09-28 | [Datapath comparison: software vs TC vs OVS-DOCA](2026-09-28-datapath-comparison.md) | n/a (performance) | ⚠️ **Under revision (#2).** Sender-side totals put TC and OVS-DOCA at parity (28.1 vs 28.8 Gbit/s); the published +13.5 % used `sum_received` and does not hold. Software path 5.5 Gbit/s |
| 2026-10-07 | [VM attach via BF3 virtio-net emulation](2026-10-07-virtio-net-emulation.md) | Items 1, 2, 3 pass · **4 met in intent, wording pending** | Stock `virtio_net` guest on a BF3-emulated device (VFIO), host vhost 0.00 cores (macvtap 1.6–1.8), host kernel CPU per Gbit/s about halved. Emulation 24.9 Gbit/s (TC) / 19.3 (OVS-DOCA) vs macvtap ~28. Lab rolled back 2026-10-08 |

Supporting files per date: `<date>/raw/` (harness output), `<date>/EVIDENCE.md` (verbatim excerpts, generated), `<date>/env/` (version pins).
Harness: [`artifacts/scripts/offload-bench/`](../../../artifacts/scripts/offload-bench/).
