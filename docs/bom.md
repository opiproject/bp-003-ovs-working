# Bill of Materials — Blueprint 003 (stub)

Pins freeze from **OPI Lab** images. Do not invent versions.

| Item | Value | Status |
|------|-------|--------|
| DPU | NVIDIA BlueField-3, **DPU mode** | Locked |
| Host OS | RHEL 9 or 10 — **lab-default minor** | NEED_LAB |
| Host kernel | | NEED_LAB |
| DOCA / BFB on DPU | | NEED_LAB |
| DOCA-Host on x86 | | NEED_LAB |
| OVS (DOCA build) | OVS-DOCA datapath | NEED_LAB |
| QEMU / libvirt | from RHEL | NEED_LAB |
| Guest NIC model | stock virtio-net + vDPA | Locked |
| Second BF3 (LM) | N/A this cycle | Deferred |
| OpenShift / CNV / DPF | | NEED_LAB (1b) |

Entitlements: OPI Lab / LF path (decision #8=A) — document procedure without secrets.
