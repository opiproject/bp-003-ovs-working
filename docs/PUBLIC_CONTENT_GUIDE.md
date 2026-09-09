# Public vs scrub — JD & onboarding

Source: `specs/Intern_JD_OVS_DPU_Offload.md`, `specs/Intern_Onboarding_Checklist.md`.  
Goal: commit-safe for `opiproject`; intern clarity without private or over-scoped promises.

---

## Intern JD

### KEEP (public)

- OPI mission one-liner; Blueprint as reference architecture (not demo).
- Track 1 technical scope: BF3, OVS-DOCA, DPDK HW vDPA, KVM (Ubuntu/Debian lab), then OpenShift Virt / DPF / OVN-K / KubeVirt.
- Required/preferred skills lists (Linux, KVM, OVS, k8s/OVN concepts, networking).
- Deliverables aligned to Framework: reproducible blueprint, validation (offload proof, perf; LM deferred per limitations).
- Profile traits: self-directed, docs-as-deliverable, works in the open.
- Sponsor line as OPI GB / contributing partner (no personal phone/email).

### SCRUB or REFRAME

| Current | Action |
|---------|--------|
| Track 2 second vendor as core JD deliverable | Move to **“Later / optional if reopened”**; v1 = Track 1 only |
| Upstream `dpu-operator` contributions as required deliverable | Reframe as **follow-on / Track 2**; not Gate B |
| “Generalizes to Intel or Marvell” in About | Soften to aspiration; point at NON_GOALS |
| Any WTIT product / Network Engine / conference framing | **Remove** (never was OPI deliverable) |
| Personal recovery / staffing / internal capacity notes | **Remove** if present |
| Deep switchdev skill as implying primary path | Keep as background knowledge; state primary path is OVS-DOCA+vDPA |

### After scrub — JD should say

v1 = BF3 reference (1a→1b). Multi-vendor and operator-parity are explicitly later.

---

## Onboarding checklist

### KEEP (public)

- Phase 1: LFID, GitHub/DCO, Slack, IDE, SSH, VPN, BF3 assignment blanks, RH/NVIDIA access blanks.
- Phase 2: governance who’s-who blanks, mentors, glossary, DPU Operator gap as **orientation** (not v1 commit).
- Phase 3: KVM/OVS/BF3/HW-vDPA standup smoke steps.
- Phase 4: define offload-validated, harness, live migration criteria, doc location.

### SCRUB or REFRAME

| Current | Action |
|---------|--------|
| “Second-vendor access (Intel/Marvell NDA)” as Phase 1 required | **Optional / later**; do not block Orient |
| Open item “Track 2 vendor selection” as pre-Phase-1 blocker | Move to sponsor decisions; not intern critical path |
| Named private individuals’ emails, VPN vendor gossip | Use **roles** (“lab admin”, “TSC liaison”); fill names in lab runbooks not git if sensitive |
| Cursor-specific / WTIT-internal tooling mandates | “IDE of choice”; optional |
| Blanks that will hold secrets (tokens, VPN configs) | Keep blank in git; store secrets out of band |

### KEEP OUT of git entirely

- Email threads, board minutes, seed timelines, selection rationale with commercial strategy → `private/` only.
- Credentials, BFB URLs with tokens, kubeconfigs, entitlement keys.

---

## Handoff notes (`INTERN_HANDOFF_NOTES.md`)

- KEEP: norms, DoD pointers, risks.
- SCRUB: paths to `SEED_CONTEXT` / private seed; do not dual-brand registry IDs — public ID is **BP-003**.
