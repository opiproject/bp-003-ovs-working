# Blueprint 003 — Non-Goals & Deferred Work

Anything here is **out of v1** unless the sponsor reopens it in [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md). Do not schedule as Gate B work.

---

## Explicitly deferred

| Item | Why deferred | Reopen signal |
|------|--------------|---------------|
| **Track 2 — second DPU/IPU** (Intel IPU or Marvell Octeon) | v1 proves one mature reference stack; multi-vendor is a separate program | Sponsor selects vendor + lab + timeline |
| **OPI / Red Hat DPU Operator** parity with NVIDIA DPF for primary OVN-K datapath + KubeVirt | Known upstream gap; not a v1 gate | Track 2 or dedicated operator epic |
| **VyOS (or other VNF) day-2 on DPU** | Different use case; confuses VM-networking reference | New blueprint or appendix epic |
| **Fabric automation** (e.g. Ansible + Arista AVD syncing DPU to underlay) | Valuable enterprise pain; not required to prove OVS offload | Optional “future work” note in narrative only |
| **Ingress / NGINX (or other) offload blueprints** | Separate TSC shortlist ideas; different BOM/partners | Distinct blueprint ID |
| **OVS-kernel / TC-flower / switchdev as primary path** | Explicitly rejected for this Blueprint’s locked path | Only if OVS-DOCA+vDPA blocked on lab HW |
| **Commercial product / SKU narratives** | OPI public artifact; no integrator product roadmap in-repo | Never in this repo |
| **Conference proposals, board minutes, email** | Process/personal; live under `private/` (gitignored) | Never commit |

---

## Soft boundaries (allowed as footnotes, not deliverables)

- Mention that a second vendor is a **community/OPI goal** without claiming it is delivered.  
- Note DPU Operator gap as **context** for why 1b uses DPF on BF3.  
- Link out to public NVIDIA/Red Hat docs; do not vendor-copy proprietary PDFs into git.

---

## Anti-patterns

- Expanding scope to “look more multi-vendor” before Gate A.  
- Treating live migration failure as silent skip (document or get sponsor accept).  
- Publishing a demo video without BOM + IaC + offload proof.
