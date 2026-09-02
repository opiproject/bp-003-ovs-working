# Phase 1b — Project direction (OpenShift Virtualization)

**If/when executed:** OpenShift Virt on BF3 via **NVIDIA DPF** + accelerated **OVN-Kubernetes** (OVS-DOCA) + **KubeVirt** on the offloaded fabric.

**Out of v1:** second vendor; OPI/RH DPU Operator as the primary path (footnote only: “later”).

---

**Default recommend: plan 1b** (sponsor: should happen). Publish bar remains best-effort gaps OK. Don’t block Summit or 1a on CNV.

| Option | Meaning |
|--------|---------|
| **A** | v1 = **1a only**; 1b = stretch / v1.1 |
| **B** | v1 = 1a + **1b architecture narrative** (gaps OK) |
| **C** | v1 blocked until DPF + CNV validated |

**Frozen:** toward **B/C hybrid** — 1b work is intended; S2=C allows shipping without full CNV if blocked. Summit does not require live 1b.

---

## Story delta

| | 1a only | +1b |
|--|---------|-----|
| Hero | OVS-DOCA + vDPA under KVM | Same offload under OpenShift Virt / DPF |
| Reader | Platform/lab engineer | Cloud / CNV platform ops |
| Control plane | Host + DPU OVS | DPF CRDs, dual-cluster ops, OVN-K on DPU |
| Multi-tenant angle | Mechanism demo | Namespace / NetworkPolicy / OVN overlay story |

---

## Gate before starting 1b build

All of:

1. 1a OVS-DOCA path works (not TC-flower theater)  
2. vDPA guest + hardware offload proven  
3. Perf method captured  
4. LM done **or** deferred with sponsor ack  
5. 1a reproducible from public docs  
6. **Access:** OpenShift + entitlements + NVIDIA BFB/DPF + BF3 worker for flash/reboot cycles  

If (6) fails → paper architecture only (option B), do not burn intern weeks on cluster plumbing.

---

## Directional risks

- DPF is **NVIDIA-specific**; say so — OPI DPU Operator is later.  
- NVIDIA ≠ OPI member → public docs/support only.  
- Dual-cluster DPF ops dominate calendar.  
- Public RDGs emphasize **pods + VFs**; **CNV/vDPA parity is the thin doc risk** — primary technical uncertainty.  
- Scope creep (HBN/SFC/telemetry): optional appendix, not core 1b.

---

## Publish sequencing

| Step | Content |
|------|---------|
| After Gate A | v1 publish candidate on 1a + directional 1b section |
| Showcase | Prefer **1a live**; 1b slides OK without live CNV |
| v1.1 | Add DPF/CNV runbook + validation when cluster allows |

**TSC wording:** “v1 ships BF3 OVS-DOCA/vDPA under KVM; OpenShift Virt via DPF is the published next step until OPI DPU Operator catches primary OVN offload.”

---

## BOM band (pin at 1b start)

| Component | Candidate / note |
|-----------|------------------|
| OpenShift + CNV | Same minor; band ~4.18–4.20 pending matrix — **NEED_SPONSOR/LAB** |
| DPF / accel OVN-K | Public RDG train (e.g. 26.4.x class) — verify at start |
| BFB | Match DPF matrix |
| OPI DPU Operator | Out of v1 |

---

## Extra sponsor picks (1b)

1. OpenShift lab this cycle? **(A)** committed · **(B)** best-effort · **(C)** none → paper only  
2. Showcase demo? **(A)** 1a live · **(B)** 1a live + 1b slides · **(C)** live CNV required  
3. If 1b starts, depth? **(A)** DPF + OVN-K pods enough · **(B)** must include CNV VM · **(C)** docs only  
4. If 1a slips past midpoint, drop 1b? **Yes** (recommended) / **No**
