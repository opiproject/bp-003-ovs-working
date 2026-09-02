# Blueprint 003 — Directional Roadmap

Derived from [`CHARTER.md`](CHARTER.md). Gates are **project** gates (TSC / showcase), not intern HR milestones.

**Status:** Stage *Build & Document*. Sponsor decisions frozen.  
**External milestone:** **OPI Summit — 15 October 2026** — lightning talk + blueprint outline / talkable progress.  
Talk outline: [`OPI_Summit_2026_Lightning_Talk.md`](OPI_Summit_2026_Lightning_Talk.md)

---

## Sequencing (locked intent)

```
Orient → Phase 1a (KVM/RHEL) → Gate A' (Summit-ready) → Phase 1b (OpenShift Virt) → Gate B → Publish
                ↑________________ Track 2 / extra vendors parked (see NON_GOALS / partners)
```

| Phase | Intent | Continue when | Kill / defer when |
|-------|--------|---------------|-------------------|
| **Orient** (≤~2 wk) | Decisions frozen; OPI Lab access; RHEL minor from lab image | Lab + DOCA path real | No HW/entitlements → Summit = outline-only honesty |
| **1a** | BF3 + OVS-DOCA + vDPA; offload proof; perf; **LM deferred** (no 2nd BF3) | Evidence + guide draft | Wrong offload path → stop, reset |
| **Gate A' — Summit** | Outline + architecture + BOM stub + offload story (+ live or recorded proof if ready) | Talk track ready mid-Oct | Don’t fake LM or multi-vendor claims |
| **Gate A** | 1a six deliverables PR-ready (LM = documented limitation) | → 1b | Demo-only → no full “published” claim |
| **1b** | DPF + accel OVN-K + KubeVirt — **should happen** | E2E **or** gaps documented | Blocked → keep best-effort narrative |
| **Gate B** | Registry publish bar (S2=C) | OPI/TSC maintenance path named | — |
| **v2** | Intel / Marvell / other lab cards | Separate reopen | Never sneak into v1 as “done” |

---

## Gates (what “done” means)

### Gate A' — Blueprint outline milestone (mid-Oct window)

Useful as an in-repo outline checkpoint (arch/BOM/status). **Josh’s OPI Summit lightning talk** (15 Oct) is prepared on the **WTIT / Network Engine** side — not tracked as a Blueprint deliverable here.

Minimum Blueprint package by mid-Oct if aiming for public outline readiness:

- Architecture 1a outline / diagram  
- BOM stub with lab pins  
- Offload status: evidence snippet or honest “in progress”  
- Partners table (supported vs targeted)  

Talk AV/slides/membership narrative: **out of scope** for this repo.

### Gate A — Phase 1a complete

- Offload proven with **named** tools/counters (hardware path, not passthrough / host soft OVS).  
- Performance table from a **version-pinned** harness.  
- Live migration: **deferred** this cycle (single BF3) — documented limitation with sponsor ack.  
- Another engineer can reproduce from public `docs/` + `artifacts/` on equivalent HW.  
- Architecture + BOM + deployment guide for 1a exist.

### Gate B — Blueprint v1 showcase-ready

Depends on sponsor **S2**:

| S2 pick | Gate B means |
|---------|----------------|
| **A** 1a-only publish | Gate A + narrative + attribution + ID reconcile; 1b marked “next” |
| **B** 1a+1b required | Gate A + 1b offload proof + dual-phase docs/IaC complete |
| **C** 1a + 1b best-effort | Gate A + 1b attempted; gaps explicit in validation/guide; still six deliverables |

**TSC / showcase bar (regardless of S2):** six Framework deliverables present, public, evidence-backed; no private email/board content; partner attribution clear; BP-003/BP-004 IDs reconciled.

---

## Success bar (project)

| Claim | Proof |
|-------|--------|
| Offload is real | Documented counter/flow procedure; fail criteria stated |
| Guest path is virtio-net over vDPA | Guest + host device evidence in validation |
| Pattern is operationalizable | IaC + ordered guide; BOM pins |
| Blueprint ≠ demo | All six deliverables; maintenance note for version bumps |
| Scope honesty | Non-goals listed; no multi-vendor claim until Track 2 reopened |

---

## Cadence

| Rhythm | Purpose |
|--------|---------|
| Weekly | Blockers, which gate we are aiming at, evidence committed |
| Per gate | Freeze pins; archive validation; update README status |
| Pre-TSC | One-page status from **public** docs only |

Execution detail: [`../specs/intern-workplan.md`](../specs/intern-workplan.md) (derived from this roadmap).
