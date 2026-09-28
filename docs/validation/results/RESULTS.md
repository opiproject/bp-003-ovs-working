# Validation results — index

Dated results for Blueprint 003, scored against [`../offload-proof-contract.md`](../offload-proof-contract.md). Raw logs sit next to each write-up; nothing here contains credentials.

| Date | Result | Contract status | Summary |
|------|--------|-----------------|---------|
| 2026-09-28 | [Offload proof: OVS-DOCA on BF3](2026-09-28-offload-proof.md) | Items 1, 2, 5 pass · 3 partial · **4 not met** | All flows `dp:doca` + `offloaded:yes`, Arm `%soft` 0.00, 0 retransmits; negative control 5.5 Gbit/s with 305,868 retransmits. Guests on macvtap, not HW vDPA yet |
| 2026-09-28 | [Datapath comparison: software vs TC vs OVS-DOCA](2026-09-28-datapath-comparison.md) | n/a (performance) | OVS-DOCA 28.76 ± 1.25 vs TC 25.33 ± 1.11 Gbit/s over 3 paired rounds (+13.5 %); software path 5.5 Gbit/s |

Supporting files per date: `<date>/raw/` (harness output), `<date>/EVIDENCE.md` (verbatim excerpts, generated), `<date>/env/` (version pins).
Harness: [`artifacts/scripts/offload-bench/`](../../../artifacts/scripts/offload-bench/).
