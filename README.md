# Multi-Tenant Network Isolation with OVS Offload on NVIDIA BlueField-3

**Blueprint ID:** BP-003  
**Stage:** Build & Document · **Category:** networking  
**Contributing partner:** WorldTech IT · **Sponsor:** Josh Brooks (OPI Governing Board)  
**Execution:** LFX mentorship — **Yash Singh** (intern); sponsor sets direction  
**Working repo:** [opiproject/bp-003-ovs-working](https://github.com/opiproject/bp-003-ovs-working) · **Publish target:** `opi-blueprints` registry

## Direction (start here)

| Doc | Purpose |
|-----|---------|
| [`START_HERE_YASH.md`](START_HERE_YASH.md) | **Intern entry** — ask, constraints, next 3 actions |
| [`docs/GOALS.md`](docs/GOALS.md) | Weekly north star |
| [`docs/CHARTER.md`](docs/CHARTER.md) | Problem, outcome, v1 vs later |
| [`docs/NON_GOALS.md`](docs/NON_GOALS.md) | Explicit deferrals |
| [`docs/SPONSOR_DECISIONS.md`](docs/SPONSOR_DECISIONS.md) | Frozen direction |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Gates A' / A / B |
| [`docs/KICKOFF_GAPS.md`](docs/KICKOFF_GAPS.md) | Open execution gaps |
| [`specs/intern-workplan.md`](specs/intern-workplan.md) | Week-by-week execution |


## What this Blueprint is

**OVS hardware offload on NVIDIA BlueField-3** for VM networking:

1. **Phase 1a — KVM (Ubuntu/Debian lab)** — BF3 DPU mode, OVS-DOCA, guests via DPDK HW vDPA + vhost-user  
2. **Phase 1b — OpenShift Virtualization** — DPF + accelerated OVN-Kubernetes / KubeVirt (**OPI showcase emphasis**)  

Offload path (locked): **OVS-DOCA** (Arm) + **DPDK hardware vDPA** (host) + stock virtio-net in guest.  
Not OVS-kernel / TC-flower / switchdev as the primary path. Not kernel `mlx5_vdpa` under DOCA-Host.

Second-vendor and other deferrals: [`docs/NON_GOALS.md`](docs/NON_GOALS.md).

**Target readers:** platform/virt engineer, OpenShift ops, network/SecOps architect.

## Partners (posture)

| Party | Role |
|-------|------|
| WorldTech IT | Contributing partner / Blueprint delivery |
| Red Hat | OpenShift Virtualization, OVN-Kubernetes (Phase 1b); optional RHEL port |
| NVIDIA | Reference DPU (BF3) + DOCA/DPF tooling (not an OPI membership claim) |

## Framework deliverables

| Deliverable | Status |
|-------------|--------|
| Reference Architecture Diagram | Gap |
| Bill of Materials | Gap |
| Deployment Guide + IaC | Gap (`artifacts/` empty) |
| Use Case Narrative | Outline — `docs/use-case-narrative.md` |
| Validation / Test Results | Gap |
| Partner Attribution | Gap |

## Links

- Framework: https://github.com/opiproject/opi/blob/main/Docs/blueprint_framework.md  
- Registry: https://github.com/opiproject/opi-blueprints/blob/main/blueprints.yaml  
- Dashboard: https://github.com/opiproject/opi-blueprints/blob/main/BLUEPRINTS.md  
- Issue: https://github.com/opiproject/opi/issues/3  
- LFX: https://mentorship.lfx.linuxfoundation.org/project/85609cd0-dcc9-4b65-be3c-7c305578a051  

Local-only sponsor context (if present) stays under `private/` (gitignored).
