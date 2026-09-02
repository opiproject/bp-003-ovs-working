# Multi-Tenant Network Isolation with OVS Offload on NVIDIA BlueField-3

**Dashboard ID:** BP-003 · **Registry ID:** BP-004 (reconcile when publishing)  
**Stage:** Build & Document · **Category:** networking  
**Contributing partner:** WorldTech IT · **Sponsor:** Josh Brooks (OPI Governing Board)  
**Execution:** LFX mentorship — **Yash Singh** (intern); sponsor sets direction

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

1. **Phase 1a — RHEL / KVM** — BF3 DPU mode, OVS-DOCA, guests via vDPA  
2. **Phase 1b — OpenShift Virtualization** — DPF + accelerated OVN-Kubernetes / KubeVirt  

Offload path (locked): **OVS-DOCA** + **vDPA** (stock virtio-net in guest).  
Not OVS-kernel / TC-flower / switchdev as the primary path.

Second-vendor and other deferrals: [`docs/NON_GOALS.md`](docs/NON_GOALS.md).

**Target readers:** platform/virt engineer, OpenShift ops, network/SecOps architect.

## Partners (posture)

| Party | Role |
|-------|------|
| WorldTech IT | Contributing partner / Blueprint delivery |
| Red Hat | RHEL, OpenShift Virtualization, OVN-Kubernetes |
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
