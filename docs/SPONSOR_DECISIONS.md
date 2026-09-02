# Sponsor decisions — Blueprint 003 direction

**Status: FROZEN 2026-08-28** (sponsor Josh Brooks)  
Engineering recommendation archive: [`DIRECTION_RECOMMENDATION.md`](DIRECTION_RECOMMENDATION.md).  
No board/personal notes here.

---

## 1. North-star outcome — **C** (+ KVM on-ramp note)

What should a TSC or customer SA believe this Blueprint proves?

- [ ] **A)** BF3 + OVS-DOCA + vDPA delivers deployable hardware-offloaded VM networking under **KVM** (RHEL as validated host)
- [ ] **B)** Same pattern, with **OpenShift Virtualization as the primary enterprise story** (KVM is only the on-ramp)
- [x] **C)** The story is **multi-vendor portability**; BF3 is only a temporary reference (even if v1 builds BF3-only)

**Sponsor note:** KVM is always the easier, lower-lift validation on-ramp (before OpenShift Virt and before second-vendor ports).

**Engineering interpretation:** Public narrative aims at a **vendor-portable pattern**. v1 **implements** the pattern on BF3 under KVM (then 1b best-effort). Do **not** claim multi-vendor until Track 2 ships; do document assumptions/interfaces so a later port is credible. Second vendor remains out of v1 deliverables (decision #5).

## 2. v1 publish / showcase bar — **C**

- [ ] **A)** Phase **1a only**; 1b = next
- [ ] **B)** **1a + 1b both required**
- [x] **C)** **1a required**; **1b best-effort** (explicit gaps OK in validation/guide)

## 3. Primary audience — **ALL (broad reach)**

- [x] **A)** Platform / virt engineer (KVM-first docs)
- [x] **B)** OpenShift / platform operations
- [x] **C)** SecOps / isolation-oriented architect as buyer; platform engineer as implementer

**Sponsor note:** Broad reach — all of the above where applicable.

## 4. Narrative lead — **C**

- [ ] **A)** Offload economics only
- [ ] **B)** Isolation boundary only
- [x] **C)** Equal weight: isolation **and** offload

## 5. Confirm v1 non-goals — **all deferred as listed**

- [x] Second DPU/IPU vendor (Track 2) — *as a v1 deliverable; still the north-star direction per #1*
- [x] OPI/RH DPU Operator parity with DPF as a publish gate
- [x] VyOS / VNF day-2 plane on DPU
- [x] Fabric automation deliverable (e.g. AVD ↔ DPU sync)
- [x] Ingress / NGINX (or other) offload as part of this Blueprint
- [ ] Other reopen: ________

## 6. Partner / branding posture — **CUSTOM (sponsor)**

- [ ] **A)** WTIT + RH; NVIDIA = hardware/tooling reference only
- [ ] **B)** WTIT lead; platforms listed factually
- [ ] **C)** Defer to publish PR
- [x] **Sponsor line:** **WTIT leading**; other **OPI members where involved**; highlight **current supported vendors** and **targeted vendors** (roadmap honesty: BF3 = current reference; second vendor = targeted / later)

## 7. Publish path — **A**

- [x] **A)** Land under current **registry-linked** blueprints repo
- [ ] **B)** `opi-poc`
- [ ] **C)** New `opiproject` repo
- [ ] **D)** Confirm with TSC liaison first

## 8. Delivery environment — **A**

- [x] **A)** OPI Lab + LF/OPI entitlements path
- [ ] **B)** WTIT/partner lab + WTIT entitlements
- [ ] **C)** Split
- [ ] **D)** Unknown

## 9. Post-intern maintenance owner — **B**

- [ ] **A)** WTIT named maintainer continues
- [x] **B)** Hand primarily to **OPI community / TSC process**
- [ ] **C)** WTIT docs / community IaC
- [ ] **D)** Decide at publish time

**Engineering note:** WTIT still sponsors delivery through Gate B; after intern, maintenance ask goes to OPI/TSC—name a community path in `partners.md` / publish PR so it isn’t orphaned.

---

## Optional 1a/1b freezes — **FROZEN 2026-08-28**

| Item | Pick | Implication |
|------|------|-------------|
| Second BF3 for live migration | **No** | **Defer LM**; document as known limitation |
| OpenShift for 1b | **Yes — should happen** | Plan 1b; publish bar still **best-effort** |
| RHEL publish pin | **9 or 10 / lab-default** | Freeze exact minor from OPI Lab image |
| Lab / onboarding | **Done** (2026-08-28 refresh) | Yash ready; OPI Lab available |
| Summit lightning talk | **Josh / WTIT·NE owns** | Out of Blueprint gap register |
| LICENSE | **OPI project handles** | Not a local kickoff gate |
| Vendors | **NVIDIA** testing; **Intel** + **Marvell** targeted; other lab cards = future | See [`partners.md`](partners.md) |

## Record

| # | Pick | Date |
|---|------|------|
| 1 | **C** (+ KVM = low-lift on-ramp) | 2026-08-28 |
| 2 | **C** | 2026-08-28 |
| 3 | **A+B+C** (broad reach) | 2026-08-28 |
| 4 | **C** | 2026-08-28 |
| 5 | all listed deferred | 2026-08-28 |
| 6 | **CUSTOM** — WTIT lead; OPI members involved; supported + targeted vendors | 2026-08-28 |
| 7 | **A** | 2026-08-28 |
| 8 | **A** | 2026-08-28 |
| 9 | **B** | 2026-08-28 |

**Hard showcase date:** OPI Summit 15 Oct — **talk owned by Josh (WTIT/NE)**; Blueprint tracks technical Gate A
