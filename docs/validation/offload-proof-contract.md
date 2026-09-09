# Offload-proof contract (V1) — ACCEPTED

**Status:** accepted by sponsor 2026-09-09; attach criterion updated 2026-09-09  
**Stack:** BF3 DPU mode · OVS-DOCA (Arm) · HW vDPA attach · stock virtio-net guest

## Pass (all required)

1. **Mode:** OVS on the DPU Arm configured for DOCA datapath (`doca-init` / `hw-offload` or equivalent documented for pinned DOCA version).  
2. **Flows under load:** data flows show hardware offload (target signals: `dp:doca` and `offloaded:yes` or DOCA-version equivalent — record exact strings from lab).  
3. **Counters:** hardware packet/pps counters rise under traffic; Arm soft path not dominating the working set.  
4. **Attach:** guest exposes stock **`virtio-net-pci`** (in-guest `virtio_net`). Host attaches via NVIDIA **hardware vDPA**: DPDK `vdpa` (or equivalent) + **vhost-user** to a host **VF** (`class=vdpa`), with the VF representor in Arm OVS-DOCA. **Not** SR-IOV VF passthrough to the guest.  
   - Kernel `mlx5_vdpa` + `/dev/vhost-vdpa-*` is **not** the Phase 1a critical path (DOCA-Host ships a dummy `mlx5_vdpa`; see troubleshooting).  
   - Evidence: QEMU/libvirt config (vhost-user socket + virtio-net-pci), DPDK vdpa bind to VF BDF, Arm `ovs-vsctl` showing VF representor, plus HW-vDPA / offload indicators under load.  
5. **Negative control:** with hw-offload disabled (or forced soft), soft path dominates — documents contrast.

## Fail

- Primary evidence is TC-flower / OVS-kernel / switchdev-only with no DOCA datapath.  
- Guest path is SR-IOV VF passthrough labeled as “vDPA offload.”  
- vhost-user / virtio-net with **no** hardware-vDPA / offload indicators (software-only attach).  
- “It feels faster” with no flow/counter artifacts.

## Candidate tools (refine on lab)

- `ovs-vsctl list Open_vSwitch` / bridge port types (Arm)  
- `ovs-appctl dpctl/dump-flows -m`  
- `ovs-appctl dpctl/offload-stats-show`  
- DPDK `vdpa` / `dpdk-vdpa` CLI; VF BDF; hugepage status  
- libvirt XML / QEMU args (vhost-user + virtio-net-pci)  
- Guest: `lspci` / ethtool showing virtio-net  

## Artifacts to file

Under `docs/validation/results/` — dated logs + short `RESULTS.md` caption. Sponsor wants **path-forward evidence** before OPI Summit (15 Oct 2026), not outline-only.

## Lab note (Yash)

Kernel `mlx5_vdpa` empty-`mgmtdev` investigation:  
https://github.com/opiproject/bp-003-ovs-working/wiki/Investigating-stub-mlx5_vdpa
