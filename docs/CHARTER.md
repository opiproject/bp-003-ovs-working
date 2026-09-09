# Blueprint 003 — Project Charter

**IDs:** **BP-003** (public / dashboard). Registry metadata reconcile at publish if needed — do not dual-brand.  
**Title:** Multi-Tenant Network Isolation with OVS Offload on NVIDIA BlueField-3  
**Stage:** Build & Document · **Category:** networking  
**Contributing partner:** WorldTech IT · **Sponsor:** Josh Brooks (OPI Governing Board)  
**Execution:** LFX mentorship (intern day-to-day; sponsor mentorship / decisions)

This page is the **project direction** for OPI + WTIT. Intern plans derive from it; they do not replace it.

---

## Problem

VM networking still burns host CPU on software OVS (or uneven NIC offload), while multi-tenant isolation depends on correct host datapath configuration. Fabric and compute teams also diverge on how DPUs/IPUs are configured relative to the underlay. Enterprises need a **vendor-documented, reproducible pattern**—not a lab anecdote—for running tenant VM traffic through OVS that is **fully hardware-offloaded to a DPU**, with proof the path is offloaded (not passthrough / host soft-switch).

## Outcome (what we are building)

An **OPI Blueprint**: a deployable reference architecture that an enterprise SA or SI can replicate. Not a feature demo. Not an RFC.

**North-star (sponsor freeze):** prove a **vendor-portable pattern** for multi-tenant VM networking via hardware-offloaded OVS. **v1 implements** that pattern on NVIDIA **BlueField-3** (mature public tooling). BF3 is the **current reference**, not the forever lock-in. **KVM** is the low-lift validation on-ramp before OpenShift Virt and before second-vendor ports. Do not claim multi-vendor until a second vendor ships; document interfaces/assumptions so Track 2 is credible later.

**v1 ships** the six Framework deliverables for the locked reference stack:

| Deliverable | Role |
|-------------|------|
| Reference Architecture Diagram | Topology SA can brief a decision-maker |
| Bill of Materials | Version-pinned HW/SW + license notes |
| Deployment Guide + IaC | Repeatable stand-up |
| Use Case Narrative | Why this pattern, for whom |
| Validation / Test Results | Offload proof, performance; LM deferred (documented limitation) |
| Partner Attribution | Who built it; who can help operationalize |

**Locked reference stack**

- DPU: NVIDIA **BlueField-3**, DPU mode  
- Offload: **OVS-DOCA** (Arm) + **DPDK hardware vDPA** (host) — guest = stock virtio-net  
- Hypervisor path: **KVM/libvirt** (Phase 1a) — acceleration on-ramp  
- Host OS for 1a: **Ubuntu/Debian** lab pin (exact release from OPI Lab BOM)  
- **Not** the primary path: OVS-kernel / TC-flower / switchdev; kernel `mlx5_vdpa` under DOCA-Host  
- Phase order: **1a KVM → 1b OpenShift Virtualization** (DPF + accelerated OVN-Kubernetes / KubeVirt); **1b is the OPI showcase** (best-effort publish bar)

NVIDIA is the **technical reference** (mature public tooling). Membership status does not change that choice.


## v1 vs later

| Horizon | In scope | Success meaning |
|---------|----------|-----------------|
| **v1** | BF3 reference: Phase 1a required; Phase 1b best-effort; document pattern for later ports | Showcase / registry-ready; multi-vendor claimed only as *direction*, not done |
| **Later** | Second vendor (Track 2); OPI/RH DPU Operator parity; fabric-automation; day-2 appliance planes | Actual multi-vendor / operator-native generalization |


## Who it is for

**Broad reach (sponsor freeze):** write for all of the following where the section applies.

| Audience | What they get |
|----------|----------------|
| **Platform / virt engineer** | How to stand up offloaded OVS + HW vDPA under KVM (Ubuntu/Debian lab host) |
| **OpenShift platform ops** | How the same intent maps via DPF + OVN-K + KubeVirt (best-effort in v1) |
| **Network / SecOps architect** | Isolation + offload rationale; what is proven vs deferred / targeted |
| **SI / contributing partner** | BOM + IaC + attribution path to services |
| **OPI TSC / community** | Adoption artifact; post-intern maintenance via OPI/TSC process |

**Not for:** board process, private sales decks, or product roadmaps of any single integrator SKU.

## Principles

1. **Direction before tickets** — charter/roadmap/non-goals bind scope; workplans follow.  
2. **Evidence over assertion** — every claim in docs has config or test evidence in-repo.  
3. **Public-by-default** — publish path is GitHub under `opiproject`; `private/` never ships.  
4. **KVM on-ramp, OpenShift Virt showcase** — Phase 1a (KVM + OVS-DOCA + HW vDPA) proves acceleration. Phase 1b OpenShift Virt is the OPI/platform showpiece (best-effort gaps OK).  
5. **Partner posture** — **WTIT leads** delivery; other **OPI members** credited where involved; call out **current supported** reference vendors (BF3) and **targeted** later vendors without claiming them as done. NVIDIA = reference silicon/tooling (not an OPI membership claim). Red Hat = member platform stack for OpenShift Virt (and optional RHEL ports). Post-intern maintenance: **OPI community / TSC process** (sponsor decision #9).
