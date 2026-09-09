# Bill of Materials — Blueprint 003 (stub)

Pins freeze from **OPI Lab** images. Do not invent versions.

| Item | Value | Status |
|------|-------|--------|
| DPU | NVIDIA BlueField-3, **DPU mode** | Locked |
| Host OS (1a) | **Ubuntu/Debian** — **lab-default release** | NEED_LAB |
| Host kernel | | NEED_LAB |
| DOCA / BFB on DPU | | NEED_LAB |
| DOCA-Host on x86 | **`doca-all`** profile; exact version from lab | PINNED_PROFILE / NEED_LAB version |
| OVS (DOCA build) | OVS-DOCA datapath on **Arm** | NEED_LAB |
| HW vDPA (host) | DPDK mlx5 vDPA + vhost-user + host VF | Locked path |
| QEMU / libvirt | from lab host distro | NEED_LAB |
| Guest NIC model | stock virtio-net + HW vDPA (not VF passthrough) | Locked |
| Second BF3 (LM) | N/A this cycle | Deferred |
| OpenShift / CNV / DPF | | NEED_LAB (1b) — OPI showcase |
| Rocky/RHEL port | Optional later — not 1a critical path | Deferred |

Entitlements: OPI Lab / LF path (decision #8=A) — document procedure without secrets.
