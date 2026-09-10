# Blueprint 003 — Goals (weekly reread)

## Goals (weekly reread)

**Derived from:** [`CHARTER.md`](CHARTER.md) · [`ROADMAP.md`](ROADMAP.md) · [`NON_GOALS.md`](NON_GOALS.md) · **frozen** [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md)  
**North-star:** ASAP² Host VF ↔ Arm OVS ↔ E-Switch ([diagram](architecture/exports/bf3-dpu-asap2-eswitch.png)); vendor-portable *pattern*; v1 proves it on BF3; **KVM** = low-lift on-ramp.  
**Publish bar:** 1a required · 1b should happen (best-effort OK). **Lab:** OPI Lab. **Maintain after intern:** OPI/TSC.  
**Summit:** mid-Oct 2026 — outline + talkable progress. **LM:** deferred (single BF3). **Vendors:** NVIDIA now; Intel + Marvell targeted; other lab cards = future.

If work invents a new offload path, skips Gate A for 1b sprawl, or pulls deferred items into v1 — **stop** and use [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md).

---

## Problem (one paragraph)

Host-CPU software switching and uneven NIC offload make multi-tenant VM networking expensive and brittle. This Blueprint delivers a **reproducible OPI reference** for full OVS hardware offload to a DPU so isolation and datapath run on the accelerator—with evidence, not slides.

## Outcome

Six Framework deliverables published for the BF3 reference: architecture, BOM, deployment guide+IaC, use-case narrative, validation results, partner attribution. Showcase-ready under the sponsor’s chosen publish bar (S2).

## Non-goals (v1)

Track 2 second vendor · DPU Operator↔DPF parity as a gate · VyOS/VNF day-2 · fabric AVD sync as deliverable · ingress/NGINX blueprints · switchdev-primary path · commercial SKU narrative · anything under `private/`. Details: [`NON_GOALS.md`](NON_GOALS.md).

## Phases

### Phase 1a — KVM (Ubuntu/Debian lab)

BF3 + OVS-DOCA; guests via **DPDK HW vDPA + vhost-user** (stock virtio-net); prove hardware offload; baseline pps/throughput; docs+IaC for 1a. **Live migration deferred** this cycle (single BF3).  
**Gate A:** independently reproducible from public repo.

### Phase 1b — OpenShift Virtualization (**OPI showcase**)

DPF + accelerated OVN-Kubernetes; KubeVirt VMs on offloaded fabric; adapt proof/harness; docs+IaC deltas.  
**Gate B:** v1 complete per S2 (1a-only / 1a+1b required / 1a+1b best-effort).

## Definition of done (project)

| Lens | Done |
|------|------|
| **Charter** | Outcome matches published artifacts; audiences addressed |
| **Gate A** | 1a evidence + reproduce path |
| **Gate B / TSC** | Six deliverables; IDs reconciled; attribution; no private content |
| **Honesty** | Deferred work listed; no multi-vendor claim |

## How success is proven

| Claim | Evidence |
|-------|----------|
| Hardware offload | Named counter/flow procedure + fail criteria in `docs/validation/` |
| virtio-net + vDPA | Guest/host device notes in results |
| Performance meaningful | Pinned harness + table |
| Live migration | Pass log or sponsor-accepted limit |
| Reproducible | Clean-ish rerun from deployment guide + `artifacts/` |
| Blueprint-grade | All six deliverables present |

## Who does what (summary)

Sponsor: direction & unblock. Intern: execute & evidence. LF/lab: access & publish repo. Red Hat / NVIDIA: platform & reference tooling—not Blueprint owners. Full map: [`STAKEHOLDERS.md`](STAKEHOLDERS.md).

## Weekly check

Aiming at Gate A or B? Which Framework row moved? Evidence path committed? Any scope reopen needed?
