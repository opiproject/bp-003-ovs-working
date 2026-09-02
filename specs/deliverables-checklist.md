# Deliverables checklist — Blueprint 003

Tracks **Framework six** + **roadmap gates**. Status: `todo` | `wip` | `blocked` | `done` | `deferred`.  
Direction: [`../docs/CHARTER.md`](../docs/CHARTER.md) · [`../docs/ROADMAP.md`](../docs/ROADMAP.md).

---

## A. Direction & publish hygiene

| ID | Item | Status | Evidence / link |
|----|------|--------|-----------------|
| D1 | Charter reviewed by sponsor | `wip` | `docs/CHARTER.md` |
| D2 | Sponsor decisions recorded | `done` | `docs/SPONSOR_DECISIONS.md` (frozen 2026-08-28) |
| D3 | Lab freezes (LM, OCP, RHEL policy, Summit) | `done` | same — optional freezes |
| D4 | Publish repo confirmed | `todo` | decision #7=A; access open |
| D5 | BP-003 / BP-004 IDs reconciled | `todo` | README + registry |
| D6 | `private/` scrub before upstream push | `todo` | pre-push checklist |

---

## B. Framework deliverables

### B1 Reference Architecture Diagram

| ID | Item | Status | Notes |
|----|------|--------|-------|
| A1 | 1a topology (host, BF3, OVS-DOCA, vDPA, tenants) | `wip` | `docs/architecture/architecture-1a.md` |
| A2 | 1b topology (DPF, OVN-K, KubeVirt) | `todo` | per S2 |
| A3 | SA-readable export (SVG/PNG) + source | `todo` | `docs/architecture/exports/` |

### B2 Bill of Materials

| ID | Item | Status | Notes |
|----|------|--------|-------|
| M1 | Server / BF3 SKU notes | `todo` | |
| M2 | RHEL + kernel + OVS-DOCA + DOCA/BFB pins | `wip` | `docs/bom.md` stub |
| M3 | OpenShift / CNV / DPF / OVN-K pins | `todo` | per S2 |
| M4 | License / entitlement notes (no secrets) | `todo` | `docs/bom.md` |

### B3 Deployment Guide + IaC

| ID | Item | Status | Notes |
|----|------|--------|-------|
| G1 | 1a ordered procedure | `wip` | `docs/deployment-guide.md` stub |
| G2 | 1a IaC under `artifacts/` | `wip` | skeletons only |
| G3 | 1b procedure + IaC | `todo` | per S2 |
| G4 | No undocumented “ask admin” gaps for published steps | `todo` | |

### B4 Use Case Narrative

| ID | Item | Status | Notes |
|----|------|--------|-------|
| N1 | Problem / personas / why DPU offload | | per S3/S4 |
| N2 | v1 vs later honesty | | links NON_GOALS |
| N3 | No commercial SKU / private sales language | | |

### B5 Validation / Test Results

| ID | Item | Status | Notes |
|----|------|--------|-------|
| V1 | Offload-proof contract agreed | `wip` | `docs/validation/offload-proof-contract.md` DRAFT |
| V2 | 1a offload evidence | `todo` | |
| V3 | 1a performance table | `todo` | harness pinned |
| V4 | 1a live migration result | `deferred` | single BF3 — see `docs/validation/limitations.md` |
| V5 | 1b validation set | `todo` | per S2 |

### B6 Partner Attribution

| ID | Item | Status | Notes |
|----|------|--------|-------|
| P1 | WTIT contributing partner | `wip` | `docs/partners.md` |
| P2 | Red Hat platform role | `wip` | same |
| P3 | NVIDIA reference HW/tooling role | `wip` | not “OPI member” claim |
| P4 | Public contact / how to engage | `todo` | `docs/partners.md` |

---

## C. Gates

| Gate | Criteria | Status | Sign-off |
|------|----------|--------|----------|
| **Gate A'** | Mid-Oct Blueprint outline checkpoint (arch/BOM/status) — not Josh’s personal talk | `wip` | Sponsor |
| **Gate A** | 1a reproducible; V1–V3; V4 deferred OK; A1; M1–M2; G1–G2 | `todo` | Sponsor |
| **Gate B** | Per S2=C + Framework rows for chosen bar | `todo` | Sponsor |
| **Publish** | D4–D6; LICENSE/DCO; README green; PR in target repo | `todo` | Sponsor + LF |

---

## D. Explicitly not tracked as v1 (see NON_GOALS)

- [ ] Track 2 second vendor — `deferred`
- [ ] DPU Operator primary OVN parity — `deferred`
- [ ] VyOS / VNF day-2 — `deferred`
- [ ] Fabric AVD sync deliverable — `deferred`
- [ ] Ingress/NGINX blueprint — `deferred`
