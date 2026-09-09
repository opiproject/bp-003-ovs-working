# OPI Project — Intern Onboarding Checklist

**Status:** Access / Orient onboarding **complete** for Yash (sponsor confirmation 2026-08-28).  
Remaining unchecked rows are optional records / Phase 1b — **not blockers** for Phase 1a lab work.

BF3 / OVS-DOCA / vDPA reference blueprint — DPU-offloaded VM networking under KVM and OpenShift Virtualization

Prepared for: LF onboarding contact  
Sponsor: Josh - OPI Governing Board  
Intern: **Yash Singh**

## Phase 1 - Accounts & Access — **DONE**

Core identity, GitHub, lab VPN, BF3 assignment, and Cursor/IDE path confirmed complete by sponsor.  
(Fill blanks below only if you want a written record for handoff.)

### Identity & Core Tools
- [x] Linux Foundation ID (LFID) created
- [x] GitHub / OPI access arranged (repos as assigned)
- [x] Git commit signing / DCO sign-off configured (or in progress per LF norms)
- [x] Slack / OPI channels available as needed
- [x] Calendar — Wed mentor block 0900–1100 with Josh

### Dev Environment
- [x] Cursor (or IDE) set up
- [x] Lab access (VPN / SSH) working
- [x] Assigned BF3 node(s) available
- [ ] Lab reservation/scheduling notes (optional): ____________________

### Red Hat / NVIDIA
- [x] Lab host OS path via OPI Lab available (Ubuntu/Debian pin)
- [ ] OpenShift cluster for 1b (when ready): ____________________
- [x] NVIDIA/DOCA download path available as needed for lab
- [ ] Second-vendor access — **deferred** (not v1)

## Phase 2 - Lay of the Land

### People & Governance
- [x] Sponsor / mentor: Josh Brooks
- [ ] Maintainers/reviewers for publish repo: ____________________ (confirm with Josh/LF when PR ready)
- [ ] Sit in on one subgroup call (optional)
- [x] Escalation: lab access → lab admin → Josh; design → Josh

### Project Orientation
- [x] Read `START_HERE_YASH.md` + CHARTER / GOALS / NON_GOALS
- [ ] Read existing BF3 / OVS-DOCA material as needed in lab
- [x] Clear on DPU Operator = later (not v1 gate)
- [x] Glossary started: `docs/glossary.md`

## Phase 3 - Technical Environment Standup — **IN PROGRESS**

- [ ] Ubuntu/Debian on assigned box — record release in `docs/bom.md`
- [ ] KVM / libvirt basic VM lifecycle
- [ ] OVS non-offloaded basics, then OVS-DOCA
- [ ] BF3 DPU mode confirmed; DOCA/BFB pinned in BOM
- [ ] Representors visible as needed for DOCA path
- [ ] DPDK HW vDPA / vhost-user path (not kernel mlx5_vdpa critical path)
- [ ] Smoke: virtio-net guest over vDPA; offload per V1 contract

## Phase 4 - Readiness Check

- [ ] Offload-proof contract mentor-accepted (`docs/validation/offload-proof-contract.md`)
- [ ] Baseline performance methodology
- [ ] Live migration — **deferred** (see `docs/validation/limitations.md`)
- [ ] OpenShift for 1b when scheduled
- [x] Documentation location = this repo (`docs/`, `artifacts/`, `specs/`)

## Deferred (not Orient blockers)

- [x] Track 2 vendor selection — later  
- [ ] Red Hat DPU Operator / cluster — 1b only  
