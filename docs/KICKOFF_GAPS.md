# Kickoff gap register — Blueprint 003

**Purpose:** Gaps for **project / Blueprint execution** (not Josh’s personal Summit talk).  
**Updated:** 2026-09-09 (host OS + attach path freeze)

**Sponsor refresh:**
- **Lab:** done (OPI Lab available).  
- **Onboarding:** done — **Yash** ready and present.  
- **Summit talk:** owned by Josh / WTIT — talk notes stay **private**; Blueprint tracks Gate A' evidence only.  
- **LICENSE / project legal shell:** handled by **OPI project**.

**Verdict:** 1a = Ubuntu/Debian KVM + DPDK HW vDPA; 1b OpenShift Virt = OPI showcase. Focus: lab pins + first HW vDPA / OVS-DOCA evidence.

**Severity:** P0 = blocks 1a progress · P1 = material · P2 = polish

---

## Closed (do not re-open)

| Item | Status |
|------|--------|
| OPI Lab VPN / BF3 access | **Done** (sponsor) |
| Intern onboarding / Yash present | **Done** |
| Direction freeze (SPONSOR_DECISIONS) | **Done** |
| JD scrub / Gate A' in workplan / stubs / LM deferred | **Done** (in-repo) |
| Summit talk prep as Blueprint gap | **N/A** — Josh / WTIT owns talk (private) |
| LICENSE as local blocker | **N/A** — OPI project handles |
| Offload-proof contract V1 | **Accepted** 2026-09-09 (attach updated) |
| Attach freeze | **DPDK HW vDPA + vhost-user** 2026-09-09 |
| 1a host OS | **Ubuntu/Debian lab** 2026-09-09 |
| DOCA-Host profile | **`doca-all`** 2026-09-09 |
| Public Blueprint ID | **BP-003** only |
| Kernel mlx5_vdpa as 1a critical path | **Rejected** (DOCA dummy; see wiki + troubleshooting) |

---

## Open — project execution (Yash + Josh mentor)

| id | sev | gap | owner | next action |
|----|-----|-----|-------|-------------|
| X01 | P0 | Confirm BF3 **DPU mode** + record FW/BFB on assigned node | Yash | Capture into `docs/bom.md` |
| X02 | P0 | Freeze **DOCA/BFB** + **Ubuntu/Debian release** from lab | Yash → Josh accept | Write pins into BOM |
| X04 | P0 | First **HW vDPA + OVS-DOCA evidence** | Yash | Per V1 contract; `docs/validation/results/` |
| X06 | P1 | Performance harness + baseline table | Yash | After offload proof |
| X07 | P1 | Architecture diagram export (PNG/SVG) | Josh | **Done** — `docs/architecture/exports/bf3-dpu-asap2-eswitch.png` (ASAP² north-star) |
| X08 | P1 | Registry-linked **write/PR path** | Josh → LF | When first PR to `opi-blueprints` is near |
| X09 | P2 | Partner engage/contact line | Josh | Optional polish on `partners.md` |

---

## Explicitly out of scope for this register

- Summit slides / AV / personal talk narrative (Josh / WTIT; **private**).  
- LICENSE/CONTRIBUTING as a kickoff gate.  
- Live migration (deferred — single BF3).  
- Track 2 Intel/Marvell validation (later).  
- Kernel `mlx5_vdpa` as Gate A path.  

---

## This week (execution)

1. Yash: DPU mode + BOM pins (X01–X02).  
2. Yash: DPDK HW vDPA path per `docs/troubleshooting/vdpa-hw-attach.md` (X04).  
3. Josh: registry access only when needed for `opi-blueprints` PR (X08).
