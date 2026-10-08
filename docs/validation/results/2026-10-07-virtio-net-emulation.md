# VM attach via BF3 virtio-net emulation: first hardware signal (contract items 1 + 4)

**Date:** 2026-10-07/08 (host UTC) · **Author:** Yash Singh · **Lab:** OPI Lab, host dh5 + BlueField-3 (DPU mode)
**Image:** BF3 `bf-bundle-3.5.0-89_26.07_ubuntu-24.04_64k_prod` (Arm kernel `6.8.0-1030-bluefield-64k`), OVS `3.5.0052`, virtio-net-controller `v26.07.10` · Host kernel `6.8.0-142-generic` · Guests Ubuntu 22.04 (`5.15.0-191-generic`)
**Raw data:** [`2026-10-07/raw/`](2026-10-07/raw/) (one folder per run + `summary.csv`, all 12 runs) · **Before/after snapshots:** [`2026-10-07/host/`](2026-10-07/host/), [`2026-10-07/arm/`](2026-10-07/arm/)
**Harness:** [`opi_emu_bench.sh`](../../../artifacts/scripts/offload-bench/opi_emu_bench.sh) (repo version of the interactive shell function these runs used; same measurements)
**Contract:** [`../offload-proof-contract.md`](../offload-proof-contract.md)
**Lab state:** all changes rolled back and verified on 2026-10-08 (see *Rollback*)

## Summary

A stock `virtio_net` guest driver runs on a **virtio-net PCI device emulated by the BF3**, passed to the VM with VFIO, with switching on the **OVS-DOCA** datapath (`dp:doca`, all flows offloaded). The host's **vhost threads use 0.00 cores** in every emulation run (vs ~1.6–1.8 cores with macvtap), and **host kernel CPU per Gbit/s is about halved**.

Over 3 paired rounds per datapath:

| Mean (n=3) | macvtap, TC | **emulation, TC** | macvtap, OVS-DOCA | **emulation, OVS-DOCA** |
|---|---|---|---|---|
| Throughput (sender) | 28.15 Gbit/s | 24.89 | 27.91 | 19.34 |
| vhost (host packet work) | 1.59 cores | **0.00** | 1.77 | **0.00** |
| Host kernel CPU | 3.46 cores | 1.41 | 3.44 | 1.14 |
| Host kernel per Gbit/s | 0.123 | **0.057** | 0.123 | **0.059** |
| VM vCPU time | 2.60 cores | 4.01 | 2.13 | 3.46 |
| Host + VM per Gbit/s | 0.215 | 0.218 | 0.200 | 0.238 |
| Retransmits (mean) | 1,400 | 17,623 | 0 | 70,618 |

**Bottom line:**
- **Host side:** packet work removed (vhost 0) and host kernel CPU per Gbit/s cut ~52–54% on both datapaths.
- **Guest side:** the guests do more work, because the device offers no receive-side segmentation offload and static PFs are fixed at MTU 1500. Total CPU per Gbit/s is about equal (TC) or higher (OVS-DOCA).
- **Emulation is slower than macvtap**, and more so under OVS-DOCA (19.3 Gbit/s, high retransmits). That cause isn't identified yet.

## Contract status

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | OVS-DOCA datapath on the Arm | **Pass** | `doca_initialized=true`; bridges `datapath_type=netdev`, ports incl. representors `type=dpdk`; `dpif/show` → `doca@ovs-doca` |
| 2 | Flows offloaded under load | **Pass** | OVS-DOCA rounds: all flows `offloaded:yes` (8/8, 4/4, 8/8; 20 × `dp:doca`) |
| 3 | Arm soft path not dominating | **Pass** | Arm `%soft` 0.00 in all runs (OVS-DOCA shows ~7% Arm busy = 1 PMD polling core, load-independent) |
| 4 | Stock virtio-net guest, hardware attach, not VF passthrough | **Met in intent; wording pending** | Guest `lspci` `1af4:1041`, `driver: virtio_net`; device provided by the BF3 (`virtnet list`: static PF); VM attach via VFIO; **vhost 0.00**. Contract text names DPDK HW vDPA + vhost-user: rewording for emulation needs sponsor approval |
| 5 | Negative control | **Pass** (28 Sep) | [`2026-09-28-offload-proof.md`](2026-09-28-offload-proof.md) |

## What changed (all reversible)

**BF3 firmware** (`mlxconfig`, applied by cold power-cycle of dh5):

| Setting | Before | After | Note |
|---|---|---|---|
| `VIRTIO_NET_EMULATION_ENABLE` | False | **True** | |
| `VIRTIO_NET_EMULATION_NUM_PF` | 0 | **2** | two static virtio-net PFs (one per VM) |
| `VIRTIO_NET_EMULATION_NUM_MSIX` | 2 | **64** | |
| `PER_PF_NUM_SF` | False | **True** | switches SF limits to per-port values |
| `PF_TOTAL_SF` (port 0 **and** port 1) | 0 | **64** | must be set on both `pciconf0` and `pciconf0.1`, see Lessons |
| `PF_SF_BAR_SIZE` (both ports) | 0 | **8** | |
| `PF_BAR2_ENABLE` | True | **False** | per NVIDIA examples; affects host-side SFs only (none in use) |
| `SRIOV_EN`, `NUM_OF_VFS` | True, 16 | **unchanged** | host SR-IOV kept; `SRIOV_EN=0` in NVIDIA's static example is optional |

**Controller (`virtnet modify`, per device):** max queue size 256 → **1024**, DIM (adaptive interrupt moderation) **enabled**.

**Arm OVS:** representors `en3f0pf0sf1000` / `en3f0pf0sf1001` in `ovsbr1` (with uplink `p0`). Rounds run twice: kernel + TC offload (`hw-offload=true`), then **OVS-DOCA** (`doca-init=true`, `netdev` bridges, `dpdk` ports, 2 GB hugepages).

**Host:** virtio functions `0d:00.2` / `0d:00.3` (`1af4:1041`) bound to `vfio-pci` (`driver_override`), attached to `opi-bench-vm1` / `opi-bench-vm2` as `<hostdev managed='yes'>`. IOMMU on; each device in its own IOMMU group.

**Guests:** `ens7` = BF3 virtio device, `driver: virtio_net`, 4 of 31 queue pairs (4 vCPUs), ring 1024.

## Method

- Two VMs on dh5, each with two test NICs: `test0` (virtio on **macvtap** over the host PF: the old path) and `ens7` (the **BF3-emulated** virtio device: the new path).
- `iperf3` vm1 → vm2, TCP, 8 streams, 60 s, **sender-side** throughput (the receiver total is unreliable, esnet/iperf#836).
- Recorded per run: host `mpstat` (host kernel = `%sys+%soft+%irq`; VM time = `%guest`), host `pidstat -t` (sum of `vhost-*` threads), receiving-VM `mpstat`, Arm `mpstat`, Arm `dpctl/dump-flows -m` at t=30 s, guest drop counters.
- 3 rounds per datapath; each round runs macvtap then emulation back-to-back.

## Results

### Kernel datapath + TC offload

| Round | Mode | Gbit/s | Retx | Host kernel | vhost | VMs | vm2 busy % | Arm soft % | Flows offloaded |
|---|---|---|---|---|---|---|---|---|---|
| 1 | macvtap | 26.08 | 4,200 | 3.03 | 1.23 | 3.32 | 51.4 | 0.00 | 7/11 |
| 1 | emulation | 26.23 | 29,222 | 1.30 | **0.00** | 4.14 | 67.5 | 0.00 | 6/8 |
| 2 | macvtap | 28.06 | 0 | 3.40 | 1.77 | 2.36 | 21.6 | 0.00 | 11/13 |
| 2 | emulation | 21.53 | 16,946 | 1.64 | **0.00** | 3.74 | 57.6 | 0.00 | 4/6 |
| 3 | macvtap | 30.32 | 0 | 3.94 | 1.78 | 2.13 | 22.0 | 0.00 | 8/10 |
| 3 | emulation | 26.90 | 6,702 | 1.28 | **0.00** | 4.16 | 69.8 | 0.00 | 4/6 |

Non-offloaded flows under TC are the switch's spanning-tree frames (`dst 01:80:c2:00:00:00`, dropped by design). Macvtap round 1 shows two extra, to be checked in its `flows_mid.txt`.

### OVS-DOCA

| Round | Mode | Gbit/s | Retx | Host kernel | vhost | VMs | vm2 busy % | Arm busy / soft % | Flows offloaded |
|---|---|---|---|---|---|---|---|---|---|
| 1 | macvtap | 28.06 | 0 | 3.19 | 1.76 | 1.99 | 14.5 | 7.16 / 0.00 | 13/13 |
| 1 | emulation | 20.15 | 58,069 | 1.15 | **0.00** | 3.41 | 52.8 | 6.96 / 0.00 | 8/8 |
| 2 | macvtap | 27.42 | 0 | 3.62 | 1.80 | 2.18 | 17.4 | 6.90 / 0.00 | 6/6 |
| 2 | emulation | 20.84 | 16,879 | 1.18 | **0.00** | 3.72 | 60.8 | 7.12 / 0.00 | 4/4 |
| 3 | macvtap | 28.26 | 2 | 3.50 | 1.76 | 2.23 | 19.5 | 7.14 / 0.00 | 8/8 |
| 3 | emulation | 17.02 | 136,908 | 1.09 | **0.00** | 3.24 | 47.5 | 7.20 / 0.00 | 8/8 |

All flows offloaded under OVS-DOCA, including the STP drop rules; the emulation rounds' flows are all `dp:doca` (20 of 20 entries).

## Interpretation

1. **The attach is in hardware.** A stock guest driver on a BF3-provided device, no host packet path (vhost 0 in all 6 emulation runs), e-switch offload under both TC and OVS-DOCA.
2. **The remaining host CPU (~1.1–1.4 cores) is not packet carrying.** It tracks the packet rate and is attributed to KVM delivering device interrupts into the VMs. DIM reduced it.
3. **The cost moves into the guests.** The device offers send-side TSO (`HOST_TSO4/6`) but not receive-side (`GUEST_TSO4/6`), and static PFs are fixed at MTU 1500 on controller v26.07.10. So the receiving guest handles ~30–40× more packets than with macvtap (100+ M vs ~3.5 M per run), which explains its higher CPU, the retransmits, and the lower throughput.
4. **OVS-DOCA did not help the emulated path here.** Macvtap is unchanged between TC and DOCA (28.2 vs 27.9 Gbit/s), but emulation dropped from 24.9 to 19.3 Gbit/s, with more retransmits and wider spread. The cause is not identified. Candidates: how OVS-DOCA programs the VM↔VM path between two SF representors on the same bridge, or interaction with the receive-side limits above. Needs investigation before any datapath claim.

## Limitations

| Limitation | Effect |
|---|---|
| Static-PF MTU fixed at 1500 (`virtnet modify -t` → "MTU is invalid"; README `static_pf` has no `mtu` option in v26.07.10) | No jumbo frames; hotplug devices accept `-t` but need `PCI_SWITCH_EMULATION_ENABLE=1` and another reset |
| No `GUEST_TSO4/6` offered by the device | Guest receives MTU-sized packets; higher guest CPU |
| Topologies differ | emulation VM↔VM stays inside the e-switch (both representors on `ovsbr1`); macvtap goes p0 → switch → p1 |
| n = 3 per datapath, single host, TCP bulk only | No pps/latency study; DIM raised idle ping RTT to ~1.6 ms |
| Guest MAC differs from controller-assigned MAC | Guests came up with random MACs on `ens7`; harmless for L2 learning, to check |

## Lessons (procedure notes)

- `PER_PF_NUM_SF=1` makes `PF_TOTAL_SF` **per port**. Setting it only on `pciconf0` left port 1 with 0 SFs, and `en3f1pf1sf0` / `enp3s0f1s0` disappeared until `pciconf0.1` was set and the card reset.
- `virtnet modify device` requires that **no virtio driver** is bound ("Virtio driver should not be loaded"). Shut the VMs down and park the functions on `vfio-pci` (sysfs `driver_override`). `virsh nodedev-detach` failed with a libvirt naming error on this host.
- Firmware changes need a **cold** power-cycle of dh5 (iDRAC "Power Cycle System (cold boot)"); a warm reboot does not reload BF3 firmware.
- OVS-DOCA switch and back: snapshot the real DB file behind the `/etc/openvswitch/conf.db` symlink, restore it with OVS stopped, and delete leftover `ovsbr*` taps. Never remove `doca-init` from the live config (it crashed `ovs-vswitchd` on 28 Sep).

## Rollback

Done on 2026-10-08 in this order. Run each block on the machine named.

```bash
# Arm: OVS-DOCA -> kernel datapath. On this BFB `openvswitch-switch` is only a wrapper:
# stopping it leaves ovsdb-server and ovs-vswitchd running, so stop them by name.
sudo systemctl stop ovs-vswitchd ovsdb-server openvswitch-switch
pgrep -a 'ovsdb-server|ovs-vswitchd' && echo "STILL RUNNING - stop here"
sudo cp ~/emu-before/conf.db.pre-doca /var/lib/openvswitch/conf.db     # real file behind the symlink; cp, never `cat > $DB`
for T in ovsbr1 ovsbr2; do ip -d link show $T 2>/dev/null | grep -q 'tun type tap' && sudo ip link del $T; done
SZ=$(awk '/Hugepagesize/{print $2}' /proc/meminfo); echo 0 | sudo tee /sys/kernel/mm/hugepages/hugepages-${SZ}kB/nr_hugepages
sudo systemctl start ovsdb-server ovs-vswitchd openvswitch-switch

# Host (dh5): detach the emulated devices and release them from vfio-pci
for V in 1 2; do virsh detach-device opi-bench-vm$V hostdev-vm$V.xml --config; done
for D in 0000:0d:00.2 0000:0d:00.3; do echo $D > /sys/bus/pci/devices/$D/driver/unbind; echo > /sys/bus/pci/devices/$D/driver_override; done

# Arm: emulation ports out of OVS, controller off, firmware back to the saved values
sudo ovs-vsctl --if-exists del-port ovsbr1 en3f0pf0sf1000 -- --if-exists del-port ovsbr1 en3f0pf0sf1001
sudo systemctl disable --now virtio-net-controller
sudo mlxconfig -y -d /dev/mst/mt41692_pciconf0 set VIRTIO_NET_EMULATION_ENABLE=0 VIRTIO_NET_EMULATION_NUM_PF=0 \
  VIRTIO_NET_EMULATION_NUM_MSIX=2 PER_PF_NUM_SF=0 PF_BAR2_ENABLE=1 PF_TOTAL_SF=0 PF_SF_BAR_SIZE=0
sudo mlxconfig -y -d /dev/mst/mt41692_pciconf0.1 set PF_TOTAL_SF=0 PF_SF_BAR_SIZE=0

# iDRAC: Power Cycle System (cold boot)
```

**Verified after the cold boot:**

| Check | Result |
|---|---|
| Firmware, both ports (`mlxconfig q`) | equal to the saved *before* values; `SRIOV_EN=1`, `NUM_OF_VFS=16` |
| Arm `ovs-vsctl show` vs the pre-emulation snapshot | identical; `other_config {hw-offload="true"}`; `dpif/show` → `system@ovs-system`, forwarding traffic |
| Arm hugepages / controller / SF reps `sf1000`, `sf1001` | 0 / disabled / gone |
| All six Arm bridge ports (`p0`, `p1`, `pf0hpf`, `pf1hpf`, both SF reps) | `up`, no OVS port errors |
| dh5 `1af4:1041` devices | 0 |
| dh5 BF3 PFs, links, VM states | same as the *before* snapshots (all VMs shut off) |

**Incident during rollback.** The Arm restore block was first run on dh5 by mistake. Its `cat … > $DB` emptied dh5's own OVS database before `cat` failed. dh5's OVS had no bridges and carries no traffic. It was recreated empty with `ovsdb-tool create`, which is the same state as before. Both fixes (stop the services by name, `cp` instead of `cat >`) are now in the procedure above and in the harness README's *Known issues*.

## Next

1. Find why emulation under OVS-DOCA is slower (flow dump of the VM↔VM path, per-port DOCA stats, repeat with fewer streams).
2. Same-topology comparison (both paths VM↔VM inside the e-switch, or both over the wire).
3. Try **hotplug** virtio devices for MTU 9000, and check whether a newer controller offers `GUEST_TSO`.
4. Sponsor decision: reword contract item 4 for virtio-net emulation.
