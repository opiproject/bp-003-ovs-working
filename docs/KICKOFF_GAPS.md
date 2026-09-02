# Kickoff gap register — Blueprint 003

**Purpose:** Gaps for **project / Blueprint execution** (not Josh’s personal Summit talk).  
**Updated:** 2026-08-28 (sponsor refresh)

**Sponsor refresh:**
- **Lab:** done (OPI Lab available).  
- **Onboarding:** done — **Yash** ready and present.  
- **Summit lightning talk:** owned on **WTIT / Network Engine** side (Josh) — **out of Blueprint repo scope**.  
- **LICENSE / project legal shell:** handled by **OPI project** — do not block local work on this.

**Verdict:** Orient access is green. Focus shifts to **technical 1a** (pins, offload-proof, evidence) and **registry PR path** when ready to publish.

**Severity:** P0 = blocks 1a progress · P1 = material · P2 = polish

---

## Closed (do not re-open)

| Item | Status |
|------|--------|
| OPI Lab VPN / BF3 access | **Done** (sponsor) |
| Intern onboarding / Yash present | **Done** |
| Direction freeze (SPONSOR_DECISIONS) | **Done** |
| JD scrub / Gate A' in workplan / stubs / LM deferred | **Done** (in-repo) |
| Summit talk prep as Blueprint gap | **N/A** — Josh / NE·WTIT owns talk |
| LICENSE as local blocker | **N/A** — OPI project handles |

---

## Open — project execution (Yash + Josh mentor)

| id | sev | gap | owner | next action |
|----|-----|-----|-------|-------------|
| X01 | P0 | Confirm BF3 **DPU mode** + record FW/BFB on assigned node | Yash | First lab session: capture into `docs/bom.md` |
| X02 | P0 | Freeze **DOCA/BFB** + **RHEL minor** from lab image | Yash → Josh accept | Write pins into BOM; no invented versions |
| X03 | P0 | **Offload-proof contract** mentor-accepted | Josh accept | Review `docs/validation/offload-proof-contract.md` |
| X04 | P0 | First **hardware offload evidence** (or clear blocker) | Yash | Per V1 contract; file under `docs/validation/results/` |
| X05 | P1 | Attach freeze: **host mlx5_vdpa** (eng default) | Josh confirm | Say A or pivot |
| X06 | P1 | Performance harness + baseline table | Yash | After offload proof |
| X07 | P1 | Architecture diagram export (PNG/SVG) for Blueprint docs | Yash | From `docs/architecture/architecture-1a.md` |
| X08 | P1 | Registry-linked **write/PR path** for Yash | Josh → LF | Confirm when first upstream PR is near |
| X09 | P2 | Partner engage/contact line | Josh | Optional polish on `partners.md` |
| X10 | P2 | BP-003 vs BP-004 reconcile | Josh + LF | At registry publish PR |

---

## Explicitly out of scope for this register

- Lightning talk slides / AV / NE membership narrative (Josh / WTIT·NE).  
- LICENSE/CONTRIBUTING boilerplate as a kickoff gate (OPI project norms).  
- Live migration (deferred — single BF3).  
- Track 2 Intel/Marvell validation (later).  

Gate A' “Summit package” in the roadmap remains useful as a **Blueprint outline milestone**, but talk delivery is not tracked here.

---

## This week (execution)

1. Yash: DPU mode + BOM pins (X01–X02).  
2. Josh: accept V1 contract + mlx5_vdpa (X03, X05).  
3. Yash: first offload evidence toward Gate A (X04).  
4. Josh: registry access only when needed for PR (X08).
