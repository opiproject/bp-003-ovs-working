# Engineering recommendation — project direction

**Status:** Sponsor decisions **frozen 2026-08-28** — see [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md).  
This file remains the pre-freeze recommendation archive; **live direction = frozen picks**, not the old defaults table.

**Frozen summary:** North-star **C** (multi-vendor *pattern*; BF3 = current reference; KVM = low-lift on-ramp) · Publish **C** (1a hard, 1b best-effort) · Audience **broad (A+B+C)** · Narrative **C** · Non-goals all deferred for v1 · Branding **WTIT lead + members + supported/targeted vendors** · Publish repo **A** · Lab **OPI Lab (A)** · Post-intern **OPI/TSC (B)**.

---

## Recommended defaults (opinionated)

| Decision | Recommend | Why (one line) |
|----------|-----------|----------------|
| **1 North-star** | **A** (KVM proof is the outcome; RHEL = reference OS) | Sponsor priority is DPU-offloaded OVS under KVM for hypervisor adoption; OpenShift is secondary packaging |
| **2 Publish bar** | **C** (1a required, 1b best-effort) | 1a must ship; 1b helps OPI/RH story if access exists |
| **3 Audience** | **C** (SecOps buyer + platform implementer) | Isolation name + implementable KVM path |
| **4 Narrative** | **C** (isolation **and** offload) | Equal weight |
| **5 Non-goals** | **All checked** | No Track 2 / operator / VyOS / AVD / ingress in v1 |
| **6 Branding** | **A** (WTIT + RH; NVIDIA = reference HW/tools) | Honest membership posture |
| **7 Publish path** | **D** then **A** | Confirm with Sridhar |
| **8 Lab / entitlements** | Escalate if unknown | 1a lab with BF3 is the critical path |
| **9 Post-intern owner** | **A** (named WTIT maintainer) | Pattern must survive past LFX for integrator reuse |

**Priority:** Phase **1a over 1b**. Do not starve KVM evidence to chase OpenShift.  
**OS note:** RHEL is the Blueprint placeholder/reference — freeze a minor for reproducibility; the portable contract is **KVM/libvirt + OVS-DOCA + vDPA**.  
**Kill v1 publish if:** cannot prove HW offload on BF3 with stock virtio-net/vDPA.  
**1a time-cut:** Offload evidence → BOM/docs → perf → LM.

---

## What “good” means for OPI

Customers/SIs can **replicate** a BF3 reference where:

1. OVS runs **OVS-DOCA** on the DPU (not host TC-flower theater).  
2. Guests stay on **stock virtio-net** via **vDPA**.  
3. Evidence pack proves **hardware** offload + a measured baseline.  
4. Six Blueprint Framework deliverables exist in a public `opiproject` repo.

That is adoption infrastructure — **not** a one-off demo.

---

## Directional architecture (locked)

```
Guest virtio-net → host vhost-vdpa → BF3 representors → OVS-DOCA → HW e-switch → wire
```

Rejected as primary: OVS-kernel/TC-flower/switchdev, VF passthrough as the guest model, OVS-DPDK-only as the hero path.

Detail: [`PHASE_1A_DIRECTION.md`](PHASE_1A_DIRECTION.md) · [`PHASE_1B_DIRECTION.md`](PHASE_1B_DIRECTION.md)

---

## Roadmap (project gates)

```
Orient → 1a (RHEL/KVM) → Gate A → 1b (OpenShift Virt) → Gate B → Publish
```

- **Gate A:** 1a independently reproducible + evidence pack  
- **Gate B:** six deliverables meet your S2 bar  

Full: [`ROADMAP.md`](ROADMAP.md)

---

## What you should do next (30 minutes)

1. Fill [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md) — accept recommendations or override.  
2. Tell us lab reality for **one** BF3 (and whether a **second** host exists for live migration).  
3. Tell us whether OpenShift for 1b is **committed / best-effort / none this cycle**.  

Engineering then freezes charter language, BOM stubs, and intern sequencing without pulling board/personal notes into git.
