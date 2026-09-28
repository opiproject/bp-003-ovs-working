# OPI BlueField-3 OVS Offload Benchmark

**Run:** 20260827T060721Z  
**Parameters:** 60s per level, 8 parallel TCP streams  
**Host:** $(hostname), kernel 6.8.0-86-generic, 64 CPUs  
**DPU:** kernel 5.15.0-1035-bluefield, 16 ARM cores  
**OVS on DPU:** ovs-vswitchd (Open vSwitch) 2.17.8+nvidia.e92ac078d  
**eSwitch:** pci/0000:03:00.0: mode switchdev inline-mode none encap-mode basic  
**DPU other_config at start:** `{hw-offload="true"}`

## Headline result

DPU ARM CPU cost of forwarding fell **18.7x** when hardware offload was
enabled, at equal or higher throughput.

## Results

| Level | Path | Forwarder | Throughput | CPU busy | Retrans | Flows offloaded |
|---|---|---|---|---|---|---|
| L1 | VM-A -> virbr0 -> VM-B | host kernel bridge | 33.01 Gbit/s | 8.02% (host) | 0 | n/a |
| L2 | VM-A -> PF -> eSwitch -> wire -> PF -> VM-B | DPU ARM kernel | 20.83 Gbit/s | 5.42% (ARM) | 27604 | 0/4 |
| L3 | same as L2 | DPU eSwitch (ASIC) | 22.67 Gbit/s | 0.29% (ARM) | 0 | 4/4 |

CPU busy is the mean across all cores for the sampling window.

### Interpretation

* **L2 vs L3 is the like-for-like comparison** — identical path and endpoints,
  only `hw-offload` differs.
* **L1 is not comparable on throughput.** It runs over a host Linux bridge and
  never touches a wire. It answers "what does software forwarding cost in host
  cores", not "how fast is this link".
* The datapath is the **kernel** one (`system@ovs-system`, no `dpdk-init`), so
  ARM %CPU is a valid metric. This is **TC hardware offload, not the OVS-DOCA
  datapath** — that is a separate configuration and was not tested.
* Guests attach via **macvtap**, not vDPA. Offload happens in the eSwitch
  regardless of guest attachment method.

## Offload evidence (per-flow)

### L2_dpu_arm_kernel

```
ufid:e4bf5f62-950e-4ce2-bfca-f920f44e6011, recirc_id(0),dp_hash(0/0),skb_priority(0/0),in_port(p0),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),eth(src=52:54:00:e7:1e:44,dst=52:54:00:70:15:af),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:378236, bytes:24984484, used:0.000s, flags:SP., dp:ovs, actions:pf0hpf
ufid:5124fe2e-e398-4ebb-9792-9f257605f4aa, recirc_id(0),dp_hash(0/0),skb_priority(0/0),in_port(p1),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),eth(src=52:54:00:70:15:af,dst=52:54:00:e7:1e:44),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:1376764, bytes:49923585053, used:0.000s, flags:SP., dp:ovs, actions:pf1hpf
ufid:62ee55cf-1f21-4737-89c9-734497087b7c, recirc_id(0),dp_hash(0/0),skb_priority(0/0),in_port(pf0hpf),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),eth(src=52:54:00:70:15:af,dst=52:54:00:e7:1e:44),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:1371154, bytes:49923498601, used:0.000s, flags:SP., dp:ovs, actions:p0
ufid:74f9e6a5-b9fe-48bd-a715-1d69905f030f, recirc_id(0),dp_hash(0/0),skb_priority(0/0),in_port(pf1hpf),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),eth(src=52:54:00:e7:1e:44,dst=52:54:00:70:15:af),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:378305, bytes:24989146, used:0.000s, flags:SP., dp:ovs, actions:p1
```

### L3_dpu_hw_offload

```
ufid:ae7ab84e-142c-4def-b037-e808e4a9ddec, skb_priority(0/0),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),recirc_id(0),dp_hash(0/0),in_port(p0),packet_type(ns=0/0,id=0/0),eth(src=52:54:00:e7:1e:44,dst=52:54:00:70:15:af),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:448444, bytes:29597412, used:0.730s, offloaded:yes, dp:tc, actions:pf0hpf
ufid:636a7dfc-aeac-4b16-9847-422e135eff59, skb_priority(0/0),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),recirc_id(0),dp_hash(0/0),in_port(p1),packet_type(ns=0/0,id=0/0),eth(src=52:54:00:70:15:af,dst=52:54:00:e7:1e:44),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:43572326, bytes:65933288777, used:0.730s, offloaded:yes, dp:tc, actions:pf1hpf
ufid:58077485-7b54-4fff-ac7d-ff00baa236c0, skb_priority(0/0),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),recirc_id(0),dp_hash(0/0),in_port(pf0hpf),packet_type(ns=0/0,id=0/0),eth(src=52:54:00:70:15:af,dst=52:54:00:e7:1e:44),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:43572326, bytes:65933288777, used:0.730s, offloaded:yes, dp:tc, actions:p0
ufid:0d676d02-34ff-41b7-988e-5f0c61189de3, skb_priority(0/0),skb_mark(0/0),ct_state(0/0),ct_zone(0/0),ct_mark(0/0),ct_label(0/0),recirc_id(0),dp_hash(0/0),in_port(pf1hpf),packet_type(ns=0/0,id=0/0),eth(src=52:54:00:e7:1e:44,dst=52:54:00:70:15:af),eth_type(0x0800),ipv4(src=0.0.0.0/0.0.0.0,dst=0.0.0.0/0.0.0.0,proto=0/0,tos=0/0,ttl=0/0,frag=no), packets:448444, bytes:29597412, used:0.730s, offloaded:yes, dp:tc, actions:p1
```

## Datapath summary during each run

### L2_dpu_arm_kernel
```
system@ovs-system: hit:54191395 missed:2317334
  ovsbr1:
    en3f0pf0sf0 3/2: (system)
    ovsbr1 65534/1: (internal)
    p0 1/3: (system)
    pf0hpf 2/4: (system)
  ovsbr2:
    en3f1pf1sf0 3/8: (system)
    ovsbr2 65534/7: (internal)
    p1 1/5: (system)
    pf1hpf 2/6: (system)
```

### L3_dpu_hw_offload
```
system@ovs-system: hit:61570363 missed:2317352
  ovsbr1:
    en3f0pf0sf0 3/2: (system)
    ovsbr1 65534/1: (internal)
    p0 1/3: (system)
    pf0hpf 2/4: (system)
  offloaded flows: 6
  offloaded packets: 100.00% (44020770/44020795)
  offloaded bytes: 100.00% (65962886189/65962889240)
  ovsbr2:
    en3f1pf1sf0 3/8: (system)
    ovsbr2 65534/7: (internal)
    p1 1/5: (system)
    pf1hpf 2/6: (system)
  offloaded flows: 6
  offloaded packets: 100.00% (44020770/44020795)
  offloaded bytes: 100.00% (65962886189/65962889242)
```

> Note: the global `offloaded packets %` above is diluted by background
> BPDU drop-flows on the uplinks. Use the per-flow evidence instead.

## CPU detail

### L1_host_software
```
Linux 6.8.0-86-generic (dh5) 	08/27/2026 	_x86_64_	(64 CPU)
Average:     all    0.00    0.00    5.37    0.00    0.00    0.00    0.00    2.64    0.00   91.98
```

### L2_dpu_arm_kernel
```
Linux 5.15.0-1035-bluefield (localhost.localdomain) 	09/19/24 	_aarch64_	(16 CPU)
Average:     all    0.16    0.00    0.36    0.01    0.00    4.90    0.00    0.00    0.00   94.58
```

### L3_dpu_hw_offload
```
Linux 5.15.0-1035-bluefield (localhost.localdomain) 	09/19/24 	_aarch64_	(16 CPU)
Average:     all    0.13    0.00    0.16    0.00    0.00    0.00    0.00    0.00    0.00   99.71
```

## Raw data

```
level,target,gbps,cpu_busy_pct,retransmits,testflows_offloaded
L1_host_software,192.168.122.30,33.01,8.02,0,n/a
L2_dpu_arm_kernel,10.99.0.11,20.83,5.42,27604,0/4
L3_dpu_hw_offload,10.99.0.11,22.67,0.29,0,4/4
```

All artifacts: `/opt/opi_experiment/metrics/run_20260827T060721Z`
