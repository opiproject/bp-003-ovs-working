# Public document set (commit-bound)

Direction lives in `docs/CHARTER.md` → `ROADMAP.md` → `NON_GOALS.md` → `STAKEHOLDERS.md`. Everything below **implements** that direction. `private/` is gitignored — never propose committing it.

---

## Tree (purpose one-liners)

```
docs/
  CHARTER.md                 # Project north star: problem, outcome, v1 vs later, audiences
  ROADMAP.md                 # Phases, Gate A/B, TSC/showcase done meaning
  NON_GOALS.md               # Explicit deferrals (Track 2, VyOS, AVD, etc.)
  STAKEHOLDERS.md            # Who decides vs executes vs unblocks
  GOALS.md                   # One-page weekly reread derived from charter/roadmap
  SPONSOR_DECISIONS.md       # A/B/C direction choices (strategic first)
  use-case-narrative.md      # SA-facing problem/personas/value (Framework #4)
  architecture/              # Diagrams + source (Framework #1)
    README.md                # How diagrams are produced / exported
    phase-1a.md              # RHEL/KVM topology notes (interim until SVG/PNG)
    phase-1b.md              # OpenShift Virt topology notes
  bom.md                     # Bill of Materials (Framework #2)
  deployment-guide.md        # Step-by-step; links into artifacts/ (Framework #3)
  validation/
    README.md                # Offload-proof contract + harness overview (Framework #5)
    results-1a.md            # 1a evidence tables / links
    results-1b.md            # 1b evidence (or “deferred per S2”)
  partners.md                # Partner attribution (Framework #6)
  PUBLIC_CONTENT_GUIDE.md    # What stays public from JD/onboarding vs scrub
  INTERN_HANDOFF_NOTES.md    # Working norms only (points at charter; no private paths)

specs/
  Intern_JD_OVS_DPU_Offload.md      # Scrubbed public scope profile (see PUBLIC_CONTENT_GUIDE)
  Intern_Onboarding_Checklist.md    # Access/standup checklist (blanks OK; no secrets)
  intern-workplan.md                # Execution plan derived from ROADMAP
  deliverables-checklist.md         # Framework six + gates acceptance tracker

artifacts/
  README.md                  # IaC index; no credentials
  ansible/                   # 1a host/DPU/OVS-DOCA/vDPA automation (as developed)
  manifests/                 # 1b OpenShift/DPF/OVN-K/KubeVirt YAML/Helm
  scripts/                   # Validation harness runners (non-secret)

references/
  OPI_Blueprint_Framework_and_FAQ.md  # What a Blueprint is / six deliverables
  MAINTENANCE_AND_UPDATES.md          # Cadence + SoT order (trim Cursor-local noise before opiproject publish)
```

**Root:** `README.md` — public landing; links charter + status table; no private seed paths.

---

## Mapping to Framework deliverables

| Framework | Path |
|-----------|------|
| Reference Architecture | `docs/architecture/` |
| BOM | `docs/bom.md` |
| Deployment Guide + IaC | `docs/deployment-guide.md` + `artifacts/` |
| Use Case Narrative | `docs/use-case-narrative.md` |
| Validation Results | `docs/validation/` |
| Partner Attribution | `docs/partners.md` |
