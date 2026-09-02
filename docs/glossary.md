# Glossary (starter)

| Term | Meaning in this Blueprint |
|------|---------------------------|
| **OVS-DOCA** | OVS datapath using DOCA Flow offload on BF3 — **primary** path |
| **vDPA** | Guest **attach** (stock virtio-net); not the switch itself — see `architecture/vdpa-and-eswitch.md` |
| **vhost-vdpa** | Host userspace/kernel attach for vDPA devices |
| **mlx5_vdpa** | NVIDIA host vDPA driver path (preferred 1a attach) |
| **E-switch** | Hardware switch in BF3; **owned by DPU Arm (ECPF) in DPU mode** |
| **ECPF** | Embedded CPU PF — Arm-side owner of NIC resources in DPU mode |
| **DPU mode** | BF3 embedded mode — DPU owns NIC + e-switch — **required** |
| **Representor** | Netdev standing in for a VF/SF/port so OVS/software can control it |
| **switchdev / TC-flower** | Often host-centric offload story — **not** this Blueprint’s primary publish path |
| **Gate A'** | Blueprint outline checkpoint (mid-Oct) | Arch/BOM/status in-repo; talk delivery is Josh/WTIT·NE |
| **Gate A** | Phase 1a reproducible + evidence |
| **Supported vs targeted** | Supported = validated now (BF3); targeted = later (Intel/Marvell/…) |

Expand as you hit new terms in lab.
