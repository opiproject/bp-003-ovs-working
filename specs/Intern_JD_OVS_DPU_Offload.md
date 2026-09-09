# Intern - DPU-Accelerated OVS Offload Blueprint

OPI (Open Programmable Infrastructure) - Linux Foundation  
Sponsor: Josh Brooks, WorldTech IT - OPI Governing Board Member

**Scope of record for v1:** see [`../docs/CHARTER.md`](../docs/CHARTER.md), [`../docs/NON_GOALS.md`](../docs/NON_GOALS.md), [`../docs/SPONSOR_DECISIONS.md`](../docs/SPONSOR_DECISIONS.md).  
This JD is aligned to the **frozen** project direction (2026-08-28). Historical LFX text that implied Track 2 / live migration as required is superseded here.

## About the project

Produce an OPI **Blueprint** for VM networking through OVS **fully hardware-offloaded** to a DPU: **KVM first** (Ubuntu/Debian lab host), then **OpenShift Virtualization** as the OPI showcase (best-effort in v1).

**Current supported reference:** NVIDIA BlueField-3 (OVS-DOCA + vDPA + DPF for OpenShift path).  
**North-star direction:** vendor-portable pattern; **Intel / Marvell / other OPI Lab cards** are **targeted later** — not v1 required deliverables.

## What you'll work on (v1)

### Phase 1a — BF3 + KVM (required)

- KVM: OVS fully offloaded to BF3 in **DPU mode** via **OVS-DOCA** (not OVS-kernel/TC-flower/switchdev as the primary path).
- Guests attach over **hardware vDPA** (stock virtio-net): **DPDK vDPA + vhost-user** on host VF; Arm OVS-DOCA.
- Prove offload is in **hardware**; baseline throughput/pps.  
- **Live migration:** deferred this cycle (single BF3) — document as a known limitation, do not block Gate A on LM.

### Phase 1b — OpenShift Virtualization (should happen; best-effort)

- BF3 via **NVIDIA DPF**, accelerated OVN-Kubernetes (OVS-DOCA), KubeVirt VMs on the offloaded fabric.  
- Gaps OK if lab/cluster blocked — document them (sponsor publish bar C).

### Explicitly later (not v1 success criteria)

- Second-vendor port (Intel IPU / Marvell Octeon / other lab cards).  
- OPI/RH DPU Operator parity with DPF as a publish gate.  
- Upstream `dpu-operator` primary OVN path as a required internship deliverable.

## Required skills

- Linux (Ubuntu/Debian lab; RHEL-family familiarity helpful): systemd, networking, kernel modules, troubleshooting
- KVM / libvirt / QEMU: VM lifecycle, virtio / vhost, vDPA concepts  
- OVS: bridges, flows, OpenFlow, datapath, hardware-offload concepts  
- Kubernetes basics: CRDs, operators, CNI — enough to grow into OpenShift Virt / OVN-K  
- Networking: L2/L3, VLAN, VXLAN/Geneve, SR-IOV (PF/VF/SF), throughput/pps testing  

## Preferred

- OVS-DOCA, DOCA SDK, DPF on BlueField  
- HW vDPA hands-on (DPDK `vdpa` / vhost-user, libvirt/QEMU)
- OVN / OVN-Kubernetes; OpenShift Virtualization  
- Go / Python / Bash; public Git / DCO workflow  

## Deliverables (v1)

- Reproducible BF3 reference (KVM required; OpenShift best-effort) with build/config docs  
- Validation: hardware offload proof + performance table; LM = documented limitation  
- Six Framework deliverables for the publish bar (see charter)  
- Mid-Oct: Blueprint outline checkpoint (arch/BOM/status) — see roadmap  

## Profile

Self-directed on thin docs; writes clearly; reproducible blueprints are a core deliverable. Works in the open.
