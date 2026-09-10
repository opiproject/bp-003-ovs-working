# Architecture — Blueprint 003

## North-star (frozen)

![BF3 DPU ASAP² / e-switch topology](exports/bf3-dpu-asap2-eswitch.png)

| Path | Purpose |
|------|---------|
| [`architecture-1a.md`](architecture-1a.md) | Phase 1a on this ASAP² / E-Switch picture |
| [`vdpa-and-eswitch.md`](vdpa-and-eswitch.md) | vDPA attach vs e-switch ownership |
| [`exports/bf3-dpu-asap2-eswitch.png`](exports/bf3-dpu-asap2-eswitch.png) | PNG export (Framework A1) |

Phase 1b OpenShift Virt reuses the same datapath under KubeVirt.
