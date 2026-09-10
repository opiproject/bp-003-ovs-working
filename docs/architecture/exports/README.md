# Diagram exports

| File | Role |
|------|------|
| `bf3-dpu-asap2-eswitch.png` | **North-star** BF3 DPU-mode ASAP² topology (Host VF / Arm OVS representors / E-Switch). Drives Phase 1a–1b narrative. |

Phase 1a still attaches VMs with **stock virtio-net + DPDK HW vDPA** on the host VF — see [`../architecture-1a.md`](../architecture-1a.md). Do not interpret VM→VF in the diagram as guest SR-IOV passthrough.
