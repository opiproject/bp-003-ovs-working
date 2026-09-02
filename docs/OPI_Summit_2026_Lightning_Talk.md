# OPI Summit 2026 — Lightning talk notes (optional)

> **Not an intern deliverable.** Josh owns this talk on the **WTIT / Network Engine** side.  
> Kept in-repo only as optional context. Yash: ignore for day-to-day Blueprint work.

**Date:** 15 October 2026  
**Format:** Lightning talk  
**Working title:** *Why WorldTech IT / Network Engine is in OPI — and why we’re sponsoring the OVS-offload Blueprint*

**Speaker context:** Josh Brooks (WTIT) — OPI Governing Board; Network Engine CTO/CPO hat for product roadmap; VAR/CRO hat for integrator lens.

**Goal:** Leave the room clear on (1) why WTIT/NE is an OPI member, (2) why we sponsor Blueprint 003, (3) why DPU/IPU offload is on the Network Engine roadmap, (4) what other integrators and end users get from OPI + IPU/DPU.

**Not the goal:** Deep DOCA/vDPA lab demo. Point at Blueprint 003 for the technical path.

---

## Suggested timing (~8–10 min)

| Min | Block | Beat |
|-----|--------|------|
| 0:00–1:00 | Hook | Multi-tenant / NVA networking still burns host CPU and soft-enforces isolation; DPUs change that—if the industry has a **portable pattern**, not one vendor’s silo. |
| 1:00–2:30 | Who we are / why OPI | WTIT = integrator + Network Engine (KVM-based hypervisor for network appliances; Proxmox packaging today). We joined OPI to push **vendor-neutral DPU/IPU operationalization**—same reason customers ask us for outcomes, not RFCs. |
| 2:30–4:30 | Why this Blueprint | Sponsoring **Multi-Tenant Network Isolation with OVS Offload**: hardware-offloaded OVS on DPU, **KVM-first** (low-lift on-ramp), then OpenShift Virt. BF3 = **current reference** in lab; Intel / Marvell / other lab cards = **targeted**. Pattern > single SKU. |
| 4:30–6:30 | Why on Network Engine roadmap | NE needs a clean OVS-on-DPU path for appliance workloads. Host NIC offload is inconsistent; DPU offload is the durable answer. Blueprint work **feeds the NE hardware/offload roadmap** while staying an OPI community artifact others can reuse. |
| 6:30–8:30 | Benefits — integrators & end users | See “Benefits” below (3–4 bullets, say them). |
| 8:30–9:30 | Status + ask | Outline live; OPI Lab; 1a KVM proof in flight; 1b OpenShift intended; LM deferred (single BF3). **Ask:** lab access, member reviews, second-vendor interest for later ports. |
| 9:30–10:00 | Close | Blueprint ≠ demo: reproducible pattern so OPI adoption sticks. |

---

## Narrative beats (speakable)

### 1. Why WTIT / Network Engine is an OPI member

- We sell and build **outcomes** on DPU/IPU-class hardware for enterprise and service-provider style workloads.  
- OPI is where **vendor-neutral APIs, operators, and blueprints** show how to operationalize that silicon—without each integrator reinventing a dead-end stack.  
- Network Engine is our KVM-based platform for network virtual appliances; membership keeps us aligned with the **open control/datapath story** customers expect next to Red Hat, F5, and other members.

### 2. Why we are sponsoring this Blueprint

- Isolation + offload is the use case we keep hearing: tenants and appliances need **harder boundaries** and **host CPU back**.  
- A Blueprint forces **architecture, BOM, guide, evidence**—not a slide.  
- KVM-first matches how many hypervisors (including ours) actually run; OpenShift Virt extends the same pattern for platform teams.  
- We lead delivery; OPI Lab + community maintain after the intern cycle.

### 3. Why this is on the Network Engine roadmap

- Today: KVM (Proxmox packaging). Gap: consistent **OVS hardware offload** onto DPU/IPU.  
- This Blueprint’s locked path (**OVS-DOCA + vDPA**, stock virtio-net guest) is the pattern we intend to carry onto **NE hardware**—proven in public, adapted in product.  
- Multi-vendor *direction* (Intel, Marvell, other lab cards) matters for a hardware matrix; BF3 is how we validate first.

### 4. Benefits for other integrators and end users

| Who | Benefit |
|-----|---------|
| **Integrators / SIs** | Reusable reference: BOM + offload-proof procedure + KVM on-ramp; services attach without inventing the datapath alone |
| **End users / operators** | Stronger isolation story (enforcement toward the DPU) + host CPU reclaim; path from KVM lab to OpenShift Virt packaging |
| **OPI ecosystem** | Adoption artifact that exercises real virt offload; feedback into operators/APIs; honest “supported vs targeted” vendor table |
| **Other DPU/IPU vendors** | Clear pattern to port against—not a proprietary one-off |

---

## Slide stub (if slides allowed — keep to ~5)

1. Title + OPI Summit  
2. WTIT / Network Engine + why OPI  
3. Blueprint 003 one-liner + KVM → OpenShift → multi-vendor direction  
4. Benefits (integrator / end user / OPI)  
5. Status (Oct 15) + ask  

---

## Honesty constraints (do not overclaim on stage)

- Do **not** claim Intel/Marvell validated in v1.  
- Do **not** claim live migration if still single-BF3.  
- Do **not** imply NVIDIA is an OPI member.  
- Do **not** turn the talk into a Network Engine sales pitch—**OPI Blueprint + shared pattern** is the center; NE is the “why we care / why it lands in product.”

---

## Repo links to mention

- Blueprint charter / roadmap / partners (supported vs targeted)  
- Registry-linked blueprints repo (publish target)  
- Issue / mentorship as appropriate  

---

## Prep checklist (pre–Oct 15)

- [ ] Confirm lightning slot length and AV with organizers  
- [ ] Freeze one architecture diagram for slide 3  
- [ ] One evidence screenshot or “in progress” lab status line (**decide by Sep 30**)  
- [ ] Align wording with [`partners.md`](partners.md) and [`CHARTER.md`](CHARTER.md)  
- [ ] Dry-run at 8 minutes against honesty list; cut benefits to three bullets if over  
- [ ] Freeze slide line: Gate A' ≠ full Blueprint publish  
- [ ] Confirm registry repo URL + write access before putting on slides  
- [ ] Pre-assign follow-up contact per closing ask  

Kickoff gaps: [`KICKOFF_GAPS.md`](KICKOFF_GAPS.md)
