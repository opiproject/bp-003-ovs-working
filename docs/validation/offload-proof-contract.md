# Offload-proof contract (V1) — DRAFT

**Status:** draft — mentor accept required  
**Stack:** BF3 DPU mode · OVS-DOCA · vDPA guest (stock virtio-net)

## Pass (all required)

1. **Mode:** OVS configured for DOCA datapath (`doca-init` / `hw-offload` or equivalent documented for pinned DOCA version).  
2. **Flows under load:** data flows show hardware offload (target signals: `dp:doca` and `offloaded:yes` or DOCA-version equivalent — record exact strings from lab).  
3. **Counters:** hardware packet/pps counters rise under traffic; Arm soft path not dominating the working set.  
4. **Attach:** guest uses stock virtio-net; host shows vDPA / `vhost-vdpa` (not VF passthrough as primary).  
5. **Negative control:** with hw-offload disabled (or forced soft), soft path dominates — documents contrast.

## Fail

- Primary evidence is TC-flower / OVS-kernel / switchdev-only with no DOCA datapath.  
- Guest path is SR-IOV VF passthrough labeled as “vDPA offload.”  
- “It feels faster” with no flow/counter artifacts.

## Candidate tools (refine on lab)

- `ovs-vsctl list Open_vSwitch` / bridge port types  
- `ovs-appctl dpctl/dump-flows -m`  
- `ovs-appctl dpctl/offload-stats-show`  
- `ovs-appctl metrics/show` or `ovs-metrics` (if present)  
- `vdpa`, sysfs / `vhost-vdpa*`, libvirt dumpxml  

## Artifacts to file

Under `docs/validation/results/` — dated logs + short `RESULTS.md` caption for Summit (Sep 30 decision: snippet or “in progress”).
