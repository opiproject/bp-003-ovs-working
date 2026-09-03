# vDPA on RHEL — Setup and Troubleshooting for BF3 DPU Mode

**For:** Yash · **Status:** Active blocker  
**Symptom:** `mlx5_vdpa` loads but `vdpa mgmtdev show` returns nothing.

---

## Why this happens

On BF3 in **DPU mode**, vDPA for VMs uses **Scalable Functions (SFs)** created on the **DPU Arm side**, not VFs on the host. The host-side `mlx5_vdpa` module loads but has nothing to bind to because:

1. **RHEL inbox `mlx5_core`** does not ship the full vDPA auxiliary-device registration paths — it builds `mlx5_vdpa` as a stub.
2. Even with DOCA-Host installed, **no SF has been created and activated on the DPU Arm** with `enable_vnet=1`, so there is no management device for `mlx5_vdpa` to register.
3. The setup runs on **two hosts** (x86 + Arm) — commands run on the wrong side produce silent nothing.

---

## Which side does what

| Action | Where | Why |
|--------|-------|-----|
| Create SFs, set `enable_vnet`, activate | **DPU Arm** | Arm owns the e-switch in DPU mode |
| Run OVS-DOCA, add SF representors to bridge | **DPU Arm** | Control plane + offload programming |
| Install DOCA-Host, load `mlx5_vdpa`/`vhost-vdpa` | **x86 Host** | Guest-attach plumbing |
| Run QEMU/libvirt with vDPA device | **x86 Host** | VM lifecycle |

---

## RHEL x86 host setup (step by step)

### 1. Install DOCA-Host (replaces inbox mlx5 drivers)

**Do not use the RHEL inbox `mlx5_core` for vDPA.** Install DOCA-Host with the `doca-all` profile.

```bash
# Pin RHEL release to prevent kernel drift
sudo subscription-manager release --set=9.4   # match your lab image

# Remove any prior OFED/DOCA
for f in $(rpm -qa | grep -i doca); do sudo yum -y remove $f; done
sudo /usr/sbin/ofed_uninstall.sh --force 2>/dev/null
sudo yum autoremove && sudo yum makecache

# Install prerequisites
sudo dnf install -y epel-release
sudo dnf install -y dkms gcc make perl mokutil \
  kernel-devel-$(uname -r) kernel-headers-$(uname -r) \
  kernel-modules-extra-$(uname -r)

# Add DOCA repo (get RPM from NVIDIA DOCA Downloads for RHEL 9)
sudo rpm -Uvh <DOCA_HOST_REPO_RPM_FOR_RHEL9>
sudo dnf makecache

# Install full DOCA stack + firmware updater
sudo dnf install -y doca-all mlnx-fw-updater

# Reboot to load DOCA kernel modules
sudo reboot
```

After reboot verify:

```bash
ofed_info            # should show DOCA version
modinfo mlx5_core | grep -E 'version|filename'
# filename should be under /lib/modules/.../updates/dkms/ or extra/mlnx-ofa_kernel/
# NOT /lib/modules/.../kernel/drivers/net/ethernet/mellanox/ (that's the inbox stub)
```

### 2. Install RShim (host ↔ DPU management)

```bash
sudo dnf install -y rshim
sudo systemctl enable --now rshim
```

### 3. Verify BF3 is in DPU mode

```bash
# From host, via mst tools
sudo mst start
sudo mlxconfig -d /dev/mst/mt41692_pciconf0 q | grep -i INTERNAL_CPU_OFFLOAD_ENGINE
# Should show: INTERNAL_CPU_OFFLOAD_ENGINE = ENABLED(0) → DPU mode
```

### 4. Load vDPA kernel modules on host

```bash
sudo modprobe vdpa
sudo modprobe vhost-vdpa
sudo modprobe mlx5_vdpa

lsmod | grep vdpa
# Should show: mlx5_vdpa, vhost_vdpa, vdpa all loaded
```

At this point `vdpa mgmtdev show` will **still be empty** — that's expected. The management device comes from the DPU Arm side.

---

## DPU Arm side setup (SSH into BF3)

SSH into the BF3 Arm OS (via RShim or OOB management IP).

### 5. Verify OVS-DOCA is running

```bash
ovs-vsctl get Open_vSwitch . other_config
# Should include: {doca-init="true", hw-offload="true"}

# If not:
ovs-vsctl --no-wait set Open_vSwitch . other_config:doca-init=true
ovs-vsctl set Open_vSwitch . other_config:hw-offload=true
systemctl restart openvswitch
```

### 6. Create Scalable Functions with vDPA enabled

This is where the `mgmtdev` comes from. Run on **DPU Arm**:

```bash
MLXDEVM=/opt/mellanox/iproute2/sbin/mlxdevm

# Identify the PF (usually pci/0000:03:00.0 on Arm side)
$MLXDEVM port show

# Create SF for PF0, controller 1 (external = host-visible), sfnum 88
$MLXDEVM port add pci/0000:03:00.0 flavour pcisf \
  pfnum 0 sfnum 88 controller 1

# Note the auxiliary device name from output, e.g. auxiliary/mlx5_core.sf.4
# Configure it
$MLXDEVM port function set <aux_dev_path> \
  hw_addr 00:00:00:00:88:01 trust on state active

# Enable vDPA networking on this SF
devlink dev param set auxiliary/mlx5_core.sf.4 \
  name enable_vnet value 1 cmode driverinit

# Reload the SF to apply
devlink dev reload auxiliary/mlx5_core.sf.4
```

### 7. Add SF representor to OVS bridge on Arm

```bash
# The SF representor appears as en3f0pf0sf88 (naming varies)
ovs-vsctl add-port br-int en3f0pf0sf88
```

---

## Back on x86 host: verify mgmtdev

### 8. Check management device

```bash
vdpa mgmtdev show
# Expected output:
#   auxiliary/mlx5_core.sf.4:
#     supported_classes net
#     max_supported_vqs 257
```

**If still empty:**

```bash
# Check auxiliary bus for mlx5 SF devices
ls /sys/bus/auxiliary/devices/ | grep mlx5_core.sf

# Check dmesg for vDPA registration
dmesg | grep -i -E "mlx5_vdpa|vdpa|mgmtdev|auxiliary"

# Verify mlx5_vdpa driver has bound to the SF
ls /sys/bus/auxiliary/drivers/mlx5_vdpa.vnet/
```

### 9. Create vDPA device and attach to VM

```bash
# Create the vDPA device
vdpa dev add name vdpa0 mgmtdev auxiliary/mlx5_core.sf.4 \
  mac 00:00:00:00:88:01

# Verify
vdpa dev show
# vdpa0: type network ... driver vhost_vdpa

# Find the character device
ls /dev/vhost-vdpa-*
# → /dev/vhost-vdpa-0
```

### 10. Configure libvirt VM with vDPA

In the VM's XML (`virsh edit <domain>`):

```xml
<devices>
  <interface type='vdpa'>
    <source dev='/dev/vhost-vdpa-0'/>
  </interface>
</devices>
```

Or QEMU command line:

```bash
-netdev type=vhost-vdpa,vhostdev=/dev/vhost-vdpa-0,id=vdpa-net0 \
-device virtio-net-pci,netdev=vdpa-net0,mac=00:00:00:00:88:01
```

Start the VM — guest sees stock **virtio-net**, no NVIDIA driver needed in guest.

---

## Diagnostic checklist

Run these and send output to Josh if stuck:

```bash
# === x86 Host ===
uname -r
cat /etc/redhat-release
ofed_info 2>/dev/null || echo "NO DOCA/OFED"
modinfo mlx5_core | grep -E 'version|filename'
modinfo mlx5_vdpa | grep -E 'version|filename'
lsmod | grep -E 'mlx5|vdpa|vhost'
ls /sys/bus/auxiliary/devices/ | grep mlx5
ls /sys/bus/auxiliary/drivers/mlx5_vdpa.vnet/
vdpa mgmtdev show
vdpa dev show
dmesg | grep -i -E "mlx5_vdpa|vdpa|mgmtdev" | tail -20

# === DPU Arm (SSH in) ===
cat /etc/mlnx-release
/opt/mellanox/iproute2/sbin/mlxdevm port show
devlink dev show
ovs-vsctl show
ovs-vsctl get Open_vSwitch . other_config
```

---

## Common failure modes on RHEL

| Symptom | Cause | Fix |
|---------|-------|-----|
| `mlx5_vdpa` loads, `mgmtdev` empty | Inbox RHEL driver (stub) | Install DOCA-Host `doca-all` |
| DOCA installed, `mgmtdev` still empty | No SF created on DPU Arm | Create SF with `enable_vnet=1` on Arm |
| SF created but host doesn't see it | SF controller ≠ 1 (external) | Recreate with `controller 1` |
| `devlink dev param set` fails | SF not in driverinit state | Set param before `state active` |
| `modprobe mlx5_vdpa` fails with key error | Secure Boot + unsigned DKMS module | Enroll MOK key or disable Secure Boot |
| `kernel-devel` mismatch | RHEL minor update changed kernel | Pin release with `subscription-manager release --set=9.X` |
| `vdpa` command not found | Old iproute2 | `dnf install iproute` (RHEL 9.1+ ships `vdpa` tool) |

---

## Key references

- [DOCA-Host Install + DKMS Guide](https://networking-docs.nvidia.com/doca/archive/3-4-0/doca-host-installation-and-dkms-management-guide)
- [BlueField Scalable Functions](https://networking-docs.nvidia.com/doca/archive/3-4-0/bluefield-scalable-functions)
- [Virtio Acceleration through Hardware vDPA](https://networking-docs.nvidia.com/doca/archive/3-4-0/virtio-acceleration-through-hardware-vdpa)
- [OVS-DOCA Hardware Acceleration](https://docs.nvidia.com/doca/archive/2-9-3/OVS-DOCA+Hardware+Acceleration/index.html)
- [Virtual Switch on BlueField](https://networking-docs.nvidia.com/doca/sdk/virtual-switch-on-bluefield)
- [SF + kernel vDPA wiki](https://github-wiki-see.page/m/Mellanox/scalablefunctions/wiki/Upstream-how-to-use-SF-kernel-vdpa-device)
