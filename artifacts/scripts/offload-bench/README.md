# offload-bench — BF3 datapath offload harness

Measures VM-to-VM traffic that crosses the BlueField-3 e-switch under three Arm-side OVS datapaths, and captures the flow, counter and CPU evidence that [`docs/validation/offload-proof-contract.md`](../../../docs/validation/offload-proof-contract.md) asks for.

| Mode | Arm OVS datapath | Role |
|------|------------------|------|
| `sw` | kernel, `hw-offload=false` | Negative control (contract item 5) |
| `tc` | kernel, `hw-offload=true` (TC offload) | Comparison only. **Not** the Blueprint's primary path |
| `doca` | OVS-DOCA: `doca-init=true`, `hw-offload=true`, `datapath_type=netdev`, `type=dpdk` ports | Primary path (contract items 1–3) |

Results from this harness: [`docs/validation/results/RESULTS.md`](../../../docs/validation/results/RESULTS.md).

## Topology

```
opi-bench-vm1 ─virtio/macvtap─ PF0 ─▶ [BF3 e-switch · Arm OVS ovsbr1: pf0hpf ↔ p0] ─▶ wire / ToR
opi-bench-vm2 ─virtio/macvtap─ PF1 ◀─ [BF3 e-switch · Arm OVS ovsbr2: p1 ↔ pf1hpf] ◀─ wire / ToR
```

- Traffic transits the e-switch and the physical wire in both directions; it never terminates on the Arm.
- Guests are stock virtio-net over **macvtap** (host kernel vhost-net). This is **not** the contract's HW vDPA attach (item 4). The harness validates the Arm/e-switch half of the datapath only.
- Test addresses: `10.99.0.1` (vm1) → `10.99.0.2` (vm2). Each VM also has a NIC on libvirt `default` for SSH.

## Files

| File | Runs on | What it does |
|------|---------|--------------|
| `opi_arm_prep.sh` | BF3 Arm (once, `sudo`) | Backs up the OVS DB and config text, installs `sysstat` and `opi_arm_mode.sh`, adds a scoped sudoers drop-in |
| `opi_arm_mode.sh` | BF3 Arm | `sw` / `tc` / `doca` / `status`. Rebuilds the existing bridges in place. Snapshots the DB before entering `doca` and restores it on exit |
| `opi_host_vms.sh` | Host | `setup` / `teardown` / `status` for the two benchmark VMs (Ubuntu 22.04 cloud image) |
| `opi_bench.sh` | Host | Per mode: switch the Arm, run iperf3, sample Arm `mpstat` for the whole run, dump flows/`dpif`/offload stats mid-run, write `REPORT.md`. Restores `tc` at the end |
| `opi_collect_env.sh` | Host | Captures the version pins (host + Arm) for `docs/bom.md` |
| `make_evidence.py` | Anywhere | Builds `EVIDENCE.md` from raw run folders by quoting their files verbatim |

## Prerequisites

- BF3 in **DPU mode**, Arm owns the e-switch, two OVS bridges already present (on the lab BFB: `ovsbr1` = `p0,pf0hpf,en3f0pf0sf0`; `ovsbr2` = `p1,pf1hpf,en3f1pf1sf0`).
- Host: KVM/libvirt, root SSH key (`/root/.ssh/id_ed25519`) authorised on the Arm user, internet access for the cloud image.
- Arm: DOCA/OVS-DOCA packages from the BFB.

## Usage

```bash
# 1. Arm prep (from the host)
scp opi_arm_prep.sh opi_arm_mode.sh <user>@<arm>:~/
ssh -t <user>@<arm> 'sudo bash ~/opi_arm_prep.sh'

# 2. VMs (host)
sudo ./opi_host_vms.sh setup          # PF0=... PF1=... to override PF names

# 3. Benchmark (host)
sudo ARM=<user>@<arm> ./opi_bench.sh sw tc doca         # one round
for i in 1 2 3; do sudo ARM=<user>@<arm> ./opi_bench.sh tc doca; done   # paired rounds

# 4. Pins + evidence
sudo ARM=<user>@<arm> ./opi_collect_env.sh <results_dir>/env
python3 make_evidence.py <results_dir>

# 5. Clean up
sudo ./opi_host_vms.sh teardown
ssh <user>@<arm> 'sudo /usr/local/sbin/opi_arm_mode.sh tc'
```

Tunables (env): `DUR` (60), `STREAMS` (8), `RESTORE` (`tc`), `HUGE_MB` on the Arm (2048), `MEM`/`CPUS` for the VMs.

Output per run: `/opt/opi_experiment/metrics/run_<UTC>/<mode>/{iperf.json,mpstat.txt,flows_mid.txt,dpif_mid.txt,offload_stats_mid.txt,ovs_config.txt,arm_mode.txt}` plus `REPORT.md`. Timestamps come from the host clock (the BF3 image had no NTP).

## Known issues (found 2026-09-28, DOCA 3.5)

1. **Leaving OVS-DOCA by editing the live config crashes `ovs-vswitchd`.** Removing `doca-init` while bridges are still `netdev`/`dpdk` aborts on restart: `conntrack-offload.c:469: assertion handles failed in conntrack_offload_config()`. `opi_arm_mode.sh` therefore restores a DB snapshot instead.
2. **`/etc/openvswitch/conf.db` is a symlink** to `/var/lib/openvswitch/conf.db` on this BFB. `cp -a` copies the link, not the database. The scripts copy through the link.
3. **Leftover taps block kernel mode.** The netdev datapath leaves persistent tap devices named after each bridge, and kernel OVS then fails with `could not add network device ovsbr1 to ofproto (File exists)`. `opi_arm_mode.sh` deletes them when leaving `doca`.
4. **Pipe + `grep -q` under `pipefail`** misdetected the OVS unit (SIGPIPE). Fixed: the scripts use `systemctl cat`.

## Changes this makes to shared hardware

| Where | Change | Revert |
|-------|--------|--------|
| Arm | `/usr/local/sbin/opi_arm_mode.sh`, `/etc/sudoers.d/opi-benchmark`, `sysstat` | `sudo rm` both files |
| Arm | OVS restarts; ends in kernel datapath + `hw-offload=true` | `opi_arm_mode.sh tc` |
| Arm | Hugepages reserved in `doca` mode | `echo 0 \| sudo tee /sys/kernel/mm/hugepages/hugepages-*/nr_hugepages` |
| Host | VMs `opi-bench-vm1/2`; `/opt/opi_experiment` | `opi_host_vms.sh teardown` |

Announce on the shared-lab thread before running: the card is shared.
