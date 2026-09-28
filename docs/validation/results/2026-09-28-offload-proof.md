# Offload proof — OVS-DOCA on BF3 (DPU mode), DOCA 3.5

**Date:** 2026-09-28 (host UTC) · **Author:** Yash Singh · **Lab:** OPI Lab, host dh5 + BlueField-3 (DPU mode)
**Scored against:** [`../offload-proof-contract.md`](../offload-proof-contract.md) (V1, accepted 2026-09-09)
**Harness:** [`artifacts/scripts/offload-bench/`](../../../artifacts/scripts/offload-bench/)
**Raw data:** [`2026-09-28/raw/`](2026-09-28/raw/) · **Verbatim excerpts:** [`2026-09-28/EVIDENCE.md`](2026-09-28/EVIDENCE.md) · **Pins:** [`2026-09-28/env/`](2026-09-28/env/)

## Verdict

**Partial pass: the Arm / e-switch half of the datapath is proven. The guest-attach half (contract item 4) is not yet done.**

Under OVS-DOCA, every data-path flow was offloaded (`dp:doca`, `offloaded:yes`), the Arm software path carried no packet work (`%soft` 0.00), and TCP ran with zero retransmits at 27.8–30.2 Gbit/s. With offload disabled (negative control), throughput fell to 5.5 Gbit/s with 305,868 retransmits. The guests in this test attach over macvtap (host kernel), **not** DPDK HW vDPA + vhost-user, so this is not yet end-to-end contract evidence.

| # | Contract criterion | Result | Evidence |
|---|--------------------|--------|----------|
| 1 | OVS on the Arm configured for the DOCA datapath | **Pass** | `doca-init=true`, `hw-offload=true`, bridges `datapath_type=netdev`, all ports `type=dpdk` (see *Offload parameters*) |
| 2 | Data flows under load show hardware offload | **Pass** | 4 of 4 OVS-DOCA runs: every flow `offloaded:yes` with `dp:doca` (6/6, 10/10, 6/6, 6/6) |
| 3 | HW counters rise; Arm soft path not dominating | **Partial** | Arm `%soft` 0.00 in every offloaded run; `dpif/show` captured mid-run. `dpctl/offload-stats-show` was **not** captured in these runs (harness updated to capture it) |
| 4 | Stock virtio-net guest over DPDK **HW vDPA** + vhost-user on a host VF | **Not met** | Guests use virtio-net over **macvtap** on the host PFs. HW vDPA attach is the next step ([`troubleshooting/vdpa-hw-attach.md`](../../troubleshooting/vdpa-hw-attach.md)) |
| 5 | Negative control: offload off → soft path dominates | **Pass** | `hw-offload=false`: 5.50 Gbit/s, 305,868 retransmits, 0/6 flows offloaded, `%soft` 1.23 |

Fail conditions checked: the primary evidence is **not** TC/kernel (TC appears only as a comparison), and the guest path is **not** VF passthrough.

## Test setup

### Topology

```
vm1 (virtio-net) ─macvtap─ host PF0 ─▶ BF3 e-switch [Arm OVS ovsbr1: pf0hpf ↔ p0] ─▶ wire ─▶ ToR
vm2 (virtio-net) ─macvtap─ host PF1 ◀─ BF3 e-switch [Arm OVS ovsbr2: p1 ↔ pf1hpf] ◀─ wire ◀─ ToR
```

Traffic goes vm1 → PF0 → e-switch → p0 → switch → p1 → e-switch → PF1 → vm2. It crosses the e-switch twice and the physical wire, and never terminates on the Arm.

### Hardware and software

| Item | Value |
|------|-------|
| DPU | NVIDIA BlueField-3, **DPU mode** (Arm owns the e-switch; host `devlink eswitch show` → *Operation not supported*) |
| DPU software | DOCA **3.5** BFB (reimaged 2026-09-14); OVS-DOCA from the BFB. Exact strings: [`env/arm.txt`](2026-09-28/env/arm.txt) |
| Arm cores | 16 |
| Host | Ubuntu, kernel `6.8.0-139-generic`, DOCA-Host 3.5 (`mlnx-ofed-kernel 2607.0.100`). Exact strings: [`env/host.txt`](2026-09-28/env/host.txt) |
| Guests | 2 × Ubuntu 22.04 cloud image, 4 vCPU / 4 GiB, virtio-net NIC on macvtap (bridge mode) per PF |
| Traffic | `iperf3` TCP, vm1 → vm2, 60 s, 8 parallel streams |

### Method

1. `opi_arm_mode.sh <mode>` reconfigures the Arm OVS and restarts it. The harness checks that vm1 → vm2 ping works before measuring.
2. iperf3 runs for 60 s. `mpstat -P ALL 1` samples the Arm for the whole run.
3. Halfway through (t = 30 s) the harness captures `ovs-appctl dpctl/dump-flows -m` and `ovs-appctl dpif/show` on the Arm, while traffic is flowing. (An end-of-run dump misses flows because they age out; `-m` is needed or the `offloaded:` annotation is omitted.)
4. The Arm is restored to `tc` mode after each run.

## Offload parameters

| Parameter | Negative control (`sw`) | Primary path (`doca`) |
|-----------|-------------------------|-----------------------|
| `other_config:doca-init` | unset | `true` |
| `other_config:hw-offload` | `false` | `true` |
| Bridge `datapath_type` | `""` (kernel, `system@ovs-system`) | `netdev` (`doca@ovs-netdev`) |
| Port `type` (`p0/p1`, `pf0hpf/pf1hpf`, SF reps) | `""` (system) | `dpdk` |
| Hugepages (Arm) | none | 2 GiB reserved |
| OVS worker model | kernel softirq | 1 PMD (poll-mode) thread, core 11 (from `ovs-vswitchd.log`) |
| Change requires OVS restart | yes | yes |

Commands used (`opi_arm_mode.sh doca`):

```bash
ovs-vsctl --no-wait set Open_vSwitch . other_config:doca-init=true
ovs-vsctl --no-wait set Open_vSwitch . other_config:hw-offload=true
systemctl restart openvswitch-switch
ovs-vsctl add-br ovsbr1 -- set bridge ovsbr1 datapath_type=netdev
ovs-vsctl add-port ovsbr1 p0 -- set Interface p0 type=dpdk      # likewise pf0hpf, SF rep; ovsbr2 for p1 side
```

## Offload signals

| Signal | Negative control `sw` (1 run) | OVS-DOCA `doca` (4 runs) | Meaning |
|--------|-------------------------------|--------------------------|---------|
| Flows `offloaded:yes` (mid-run) | 0 / 6 | 6/6 · 10/10 · 6/6 · 6/6 | Every data flow is in hardware |
| Datapath tag on flows | `dp:ovs` | `dp:doca` | Flows installed through DOCA Flow |
| Arm `%soft` (softirq, all cores) | 1.23 | 0.00 (all 4) | No packet processing in the Arm kernel |
| TCP retransmits (60 s) | 305,868 | 0 (all 4) | Soft path drops packets; hardware path doesn't |
| Throughput | 5.50 Gbit/s | 23.94 · 30.17 · 27.80 · 28.30 Gbit/s | 4.4–5.5× the soft path |
| Arm busy | 2.13 % (0.34 cores) | 7.05–7.15 % (≈1.13 cores) | See note below |

The exact flow strings behind these counts are in [`EVIDENCE.md`](2026-09-28/EVIDENCE.md).

**Reading the Arm CPU number.** In `doca` mode about 1.13 cores stay busy with `%soft` at 0.00. That is the DPDK PMD thread busy-polling its queues (log: `PMD thread on numa_id: 0, core id: 11, max sleep: 0 us`), and it costs the same whether traffic flows or not. It is a fixed cost of the OVS-DOCA model, not per-packet work. In `sw` mode the Arm looks almost idle (hottest core: 6.75 % softirq, 92.7 % idle) yet throughput collapses. The soft path's limit is packet loss on the way to and from the Arm, not CPU exhaustion. So **throughput and retransmits, not Arm CPU %, are the evidence of offload** on this card.

## Flows that were not offloaded

- **`doca` runs:** none. Every flow in all 4 runs was offloaded.
- **`tc` comparison runs:** 2 flows per run were `dp:ovs` without `offloaded:yes`. In run `20260928T144857Z` both were inspected: `eth(dst=01:80:c2:00:00:00)` from the switch (`44:4c:a8:…`) on `p0` and `p1`, `actions:drop`. These are link-local spanning-tree control frames that OVS drops in software by design, not test traffic. The other `tc` runs are listed in full in [`EVIDENCE.md`](2026-09-28/EVIDENCE.md).

## What this does not prove

| Gap | Status |
|-----|--------|
| Guest attach over DPDK HW vDPA + vhost-user (contract item 4) | **Next step.** Guests here use macvtap, so the host kernel still touches every packet between guest and PF |
| `dpctl/offload-stats-show` and e-switch HW packet counters | Not captured in these runs; the harness now captures `offload-stats-show` mid-run |
| Packet rate (pps) / small packets | Not measured. TCP bulk only |
| Live migration | Deferred (single BF3). See [`../limitations.md`](../limitations.md) |
| Other topologies (VF-based, >2 VMs, tenant isolation policies) | Not tested |

## Known issues found during this run (DOCA 3.5)

1. **Leaving OVS-DOCA by editing the live config crashes `ovs-vswitchd`.** After removing `doca-init` while bridges were still `netdev`/`dpdk`, the restart aborted:
   `util|EMER|../lib/conntrack-offload.c:469: assertion handles failed in conntrack_offload_config()`.
   OVS on the Arm was down for ~30 min while it was restored by rebuilding the kernel bridges. This may be an unsupported sequence rather than a defect. The harness now restores a pre-DOCA DB snapshot instead. The measurement itself (run `20260928T150444Z`) had already completed.
2. **`/etc/openvswitch/conf.db` is a symlink** to `/var/lib/openvswitch/conf.db` on this BFB, so `cp -a` backups are useless.
3. **Leftover tap devices** named after each bridge (`tun type tap … persist on`) block kernel OVS from creating its bridge-internal port afterwards (`could not add network device ovsbr1 to ofproto (File exists)`). Delete them when leaving `doca`.

## Reproduce

See [`artifacts/scripts/offload-bench/README.md`](../../../artifacts/scripts/offload-bench/README.md). The short form:

```bash
sudo ./opi_host_vms.sh setup
sudo ARM=<user>@<arm> ./opi_bench.sh sw doca
python3 make_evidence.py docs/validation/results/<date>
```

## Runs in this record

| Run (host UTC) | Modes | Note |
|----------------|-------|------|
| `20260928T144857Z` | `sw`, `tc` | Negative control + TC comparison |
| `20260928T150444Z` | `doca` | First OVS-DOCA run; restore-to-`tc` crashed afterwards (Known issue 1) |
| `20260928T155730Z` | `tc`, `doca` | Paired round 1 (fixed harness) |
| `20260928T160023Z` | `tc`, `doca` | Paired round 2 |
| `20260928T160315Z` | `tc`, `doca` | Paired round 3 |

Performance comparison of these runs: [`2026-09-28-datapath-comparison.md`](2026-09-28-datapath-comparison.md).
