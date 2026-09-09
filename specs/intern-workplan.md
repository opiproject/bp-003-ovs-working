# Intern workplan — derived from project roadmap

**This is execution detail, not project direction.**  
Direction: [`../docs/CHARTER.md`](../docs/CHARTER.md) · [`../docs/ROADMAP.md`](../docs/ROADMAP.md) · [`../docs/GOALS.md`](../docs/GOALS.md) · [`../docs/KICKOFF_GAPS.md`](../docs/KICKOFF_GAPS.md)  
Tracker: [`deliverables-checklist.md`](deliverables-checklist.md)  
Status: `todo` | `wip` | `blocked` | `done` | `deferred`

Do not schedule Track 2 / deferred items without sponsor reopen.

---

## 0. Orient — **largely complete**

- [x] Access / onboarding (Yash ready; OPI Lab done — sponsor 2026-08-28)
- [ ] Confirm BF3 **DPU mode** + record Ubuntu/Debian release + DOCA/BFB from lab → BOM
- [ ] Offload-proof contract → mentor accept (V1)
- [x] Stubs landed: architecture, bom, validation, artifacts skeletons
- [ ] **Exit to 1a:** pins frozen + V1 accepted + first offload attempt

---

## 0b. Blueprint outline checkpoint (mid-Oct)

In-repo outline (arch/BOM/status). **Not** Josh’s personal Summit lightning-talk workstream.

- [ ] Architecture 1a diagram export
- [ ] BOM with lab pins
- [ ] Offload evidence or honest in-progress note
- [ ] Partners supported vs targeted accurate

---

## 1. Phase 1a → Gate A

### Environment

- [ ] Ubuntu/Debian (lab-default release); KVM lifecycle on non-offloaded path
- [ ] Software OVS basics, then BF3 DPU mode + OVS-DOCA
- [ ] DPDK HW vDPA + vhost-user; virtio-net guest (not kernel mlx5_vdpa critical path)

### Prove & measure

- [ ] Hardware offload evidence (V2)
- [ ] Performance harness + table (V3)
- [ ] Live migration (V4) → **`deferred`** (single BF3); keep `docs/validation/limitations.md` current

### Package

- [ ] Architecture 1a (A1)
- [ ] BOM 1a (M1–M2)
- [ ] Deployment guide + IaC (G1–G2)
- [ ] Attribution stub (P1–P4)
- [ ] **Gate A sign-off**

---

## 2. Phase 1b → Gate B (should happen; best-effort)

- [ ] OpenShift / CNV access
- [ ] DPF + accelerated OVN-K; KubeVirt on offloaded fabric
- [ ] Validation 1b (V5) or gaps documented (S2=C)
- [ ] Arch 1b, BOM++, guide+IaC, narrative final (N1–N3)
- [ ] **Gate B sign-off**

---

## 3. Publish

- [ ] ID hygiene (public **BP-003**); README status; maintenance note
- [ ] LICENSE / DCO / CONTRIBUTING present
- [ ] PR to registry-linked `opiproject` repo
- [ ] TSC one-pager from public docs only
- [ ] Post-intern maintainer path named (decision #9)

---

## Weekly status (mentor — Wed office hours)

- Gate aim (A' / A / B / Publish):
- Framework IDs moved:
- Evidence paths:
- Blockers (access vs decision):
- Decision asks (sponsor # only):
