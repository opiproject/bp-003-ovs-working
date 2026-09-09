# Glossary (starter)

| Term | Meaning in this Blueprint |
|------|---------------------------|
| **OVS-DOCA** | OVS datapath using DOCA Flow offload on BF3 — **primary** path |
| **vDPA** | Guest **attach** (stock virtio-net); not the switch itself — see `architecture/vdpa-and-eswitch.md` |
| **DPDK HW vDPA** | Userspace mlx5 vDPA PMD + **vhost-user** — **Phase 1a attach** |
| **vhost-user** | QEMU socket backend for HW vDPA (not kernel `/dev/vhost-vdpa-*`) |
| **mlx5_vdpa** | NVIDIA kernel vDPA module — **not** Phase 1a path under DOCA-Host (dummy) |
| **vhost-vdpa** | Kernel chardev attach (`/dev/vhost-vdpa-*`) — demoted for 1a under DOCA |
| **E-switch** | Hardware switch in BF3; **owned by DPU Arm (ECPF) in DPU mode** |
| **ECPF** | Embedded CPU PF — Arm-side owner of NIC resources in DPU mode |
| **DPU mode** | BF3 embedded mode — DPU owns NIC + e-switch — **required** |
| **Representor** | Netdev standing in for a VF/SF/port so OVS/software can control it |
| **switchdev / TC-flower** | Often host-centric offload story — **not** this Blueprint’s primary publish path |
| **Gate A'** | Mid-Oct outline checkpoint (arch/BOM/evidence); talk delivery is Josh/WTIT (**private**) |
| **Gate A** | Phase 1a reproducible + evidence |
| **Supported vs targeted** | Supported = validated now (BF3); targeted = later (Intel/Marvell/…) |

Keep this short; link architecture docs for depth.
