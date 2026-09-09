# HW vDPA attach — BF3 DPU mode (Phase 1a)

**For:** Yash · **Status:** Active path (supersedes kernel `mlx5_vdpa` critical path)  
**Symptom addressed:** `mlx5_vdpa` loads but `vdpa mgmtdev show` is empty under DOCA-Host.

Lab write-up: [Investigating-stub-mlx5_vdpa](https://github.com/opiproject/bp-003-ovs-working/wiki/Investigating-stub-mlx5_vdpa)

---

## Why kernel `mlx5_vdpa` is not the 1a path

DOCA-Host ships an explicit **dummy** `mlx5_vdpa` module (ABI fence). Hardware can still create `mlx5_core.vnet.*` on a VF — that does **not** yield a working kernel vDPA backend under DOCA.

NVIDIA’s documented **ASAP2 Hardware vDPA** path is:

| Side | Role |
|------|------|
| **x86 host** | DOCA-Host `doca-all`; create **VF**; DPDK **`vdpa`** with `class=vdpa` on VF BDF; **vhost-user** socket → QEMU `virtio-net-pci` |
| **DPU Arm** | E-switch owner (switchdev already on); **OVS-DOCA**; add **VF representor** (`pf0vfN`) to bridge |
| **Guest** | Stock virtio-net — no NVIDIA driver |

That still **fully offloads**: virtio datapath in HW + OVS flows via DOCA to the e-switch. Pass/fail: [`../validation/offload-proof-contract.md`](../validation/offload-proof-contract.md).

---

## Host OS

Phase 1a lab pin: **Ubuntu/Debian** (exact release → `docs/bom.md`).  
Rocky/RHEL is an optional later port — not required to prove acceleration.

---

## Ordered outline (fill versions from lab)

### Arm

1. Confirm DPU mode / BFB pin; OVS-DOCA (`doca-init`, `hw-offload`).  
2. After host creates VFs, confirm representors (`pf0vfN`).  
3. Add representor to OVS-DOCA bridge with uplink/`p0` as required by pin.

### x86 host

1. Install DOCA-Host **`doca-all`** (+ FW updater as needed); reboot.  
2. Create VF(s) on the host PF (`sriov_numvfs`).  
3. Hugepages (1G shared typical for the DPDK sample).  
4. Build/run DPDK `vdpa` / `dpdk-vdpa` against **VF BDF** (`class=vdpa`); `create` vhost-user socket.  
5. libvirt/QEMU: vhost-user → `virtio-net-pci` (`page-per-vq=on`).  
6. Collect contract artifacts under `docs/validation/results/`.

**Do not (DPU mode):** expect host `devlink eswitch set switchdev`, or treat empty `vdpa mgmtdev show` as the success signal.

---

## References

- [Virtio Acceleration through Hardware vDPA](https://networking-docs.nvidia.com/doca/archive/3-4-0/virtio-acceleration-through-hardware-vdpa)  
- [OVS-DOCA Hardware Acceleration](https://networking-docs.nvidia.com/doca/archive/3-4-0/ovs-doca-hardware-acceleration)  
- [DOCA Switching / DPU mode](https://networking-docs.nvidia.com/doca/archive/3-4-0/doca-switching)  
- [DPDK mlx5 vDPA PMD](https://doc.dpdk.org/guides/vdpadevs/mlx5.html)
