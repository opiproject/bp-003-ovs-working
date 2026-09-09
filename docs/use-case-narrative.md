# Use Case Narrative — outline (Framework #4)

**Audience:** solutions architects, platform engineers, network/SecOps architects  
**Tone:** public OPI reference — outcomes and patterns, not integrator sales  
**Align:** sponsor S3 (persona) · S4 (isolation vs offload emphasis)  
**Status:** outline — expand to full prose after S3/S4

---

## 1. Executive summary

- One paragraph: multi-tenant VM networking with **OVS hardware-offloaded to a DPU** (BF3 reference).
- What the reader can replicate: Phase 1a KVM (Ubuntu/Debian lab); Phase 1b OpenShift Virtualization (OPI showcase; per publish bar).
- What success looks like: offload proven, BOM/guide/IaC in hand, host CPU reclaimed for workloads.

## 2. Problem statement

- Host soft-switch / uneven NIC offload cost and operational complexity.
- Multi-tenant isolation depends on correct datapath placement (DPU vs host).
- Gap between DPU vendor demos and **enterprise-reproducible** architecture docs.
- Why OPI Blueprint form (six deliverables) beats a one-off PoC.

## 3. Who this is for

- Primary persona (S3): platform/virt · OpenShift ops · or SecOps-buyer + platform implementer.
- Secondary: SI/integrator packaging the pattern; TSC readers evaluating adoption value.
- Out of audience: board process, product SKU buyers for a single commercial hypervisor.

## 4. Solution pattern

- Reference DPU: NVIDIA BlueField-3 in DPU mode.
- Datapath: **OVS-DOCA**; guest attach: **vDPA** / stock virtio-net.
- Phase 1a: Ubuntu/Debian + KVM/libvirt + DPDK HW vDPA.
- Phase 1b: OpenShift Virtualization via DPF + accelerated OVN-Kubernetes + KubeVirt.
- Explicit: not the OVS-kernel/TC-flower/switchdev primary path.

## 5. Why DPU offload matters here

- Per S4: performance/CPU reclaim · isolation boundary · or equal weight.
- What moves to the DPU vs what remains on the host.
- Live migration and day-2 expectations (honest limits).

## 6. Deployment journey (pointer, not the guide)

- High-level stages only; deep steps live in `deployment-guide.md` + `artifacts/`.
- Validation posture: how an SA knows offload is real (pointer to `validation/`).

## 7. Outcomes & evidence

- Isolation / offload claims tied to published results.
- Performance: how to read the tables (methodology, not marketing numbers).

## 8. Scope honesty (v1 vs later)

- In v1: BF3 reference, phases per roadmap.
- Deferred: second vendor, DPU Operator parity, fabric automation, other blueprints — link `NON_GOALS.md`.
- No multi-vendor interoperability claim until delivered.

## 9. Partners & next steps

- Roles: WTIT (contributing), Red Hat (platform), NVIDIA (reference HW/tooling).
- How to try: lab/BOM path; how to engage contributing partner (`partners.md`).
- Feedback loop into OPI (gaps surfaced for APIs/operators — without promising Track 2).

## 10. References

- Architecture, BOM, deployment guide, validation, Framework FAQ, registry entry.
