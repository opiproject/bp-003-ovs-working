# Working norms (execution)

Project direction: [`CHARTER.md`](CHARTER.md) · [`ROADMAP.md`](ROADMAP.md) · [`GOALS.md`](GOALS.md) · [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md) (frozen).  
Kickoff gaps: [`KICKOFF_GAPS.md`](KICKOFF_GAPS.md).  
Do not treat this file as scope of record.

## Expectations

- Sponsor sets direction and unblocks partners/lab; intern owns day-to-day build, evidence, PRs.
- Modular, auditable work so another engineer can continue after the mentorship term.
- Small PRs by deliverable area; every claim → config artifact or test evidence.
- Public paths only: `docs/`, `specs/`, `artifacts/`, `references/`. Never commit `private/`.

## Cadence

- **Mentor office hours:** Wednesdays **0900–1100** (confirm timezone with Josh — typically US Central unless stated otherwise).
- **Intern:** Yash Singh — onboarded; OPI Lab access available.
- Weekly status against Gate A (1a), then 1b best-effort. Blueprint outline milestones are in-repo; Josh’s OPI Summit lightning talk is owned on the WTIT/NE side (not a Blueprint ticket).

## Near-term

1. Pins from lab: DPU mode, DOCA/BFB, RHEL minor → `docs/bom.md`.  
2. Mentor accept offload-proof contract (`docs/validation/offload-proof-contract.md`).  
3. Drive Phase 1a offload evidence → Gate A.  
4. Track acceptance in [`../specs/deliverables-checklist.md`](../specs/deliverables-checklist.md).

## Risks

- Lab/VPN/BF3 access latency (P0).  
- Version skew: DOCA ↔ RHEL ↔ OpenShift.  
- Ambiguous offload-proof methodology until V1 accepted.  
- Scope pressure toward Track 2 / LM before Gate A — refuse; use NON_GOALS + limitations.md.
