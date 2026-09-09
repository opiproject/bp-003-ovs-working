# How the pieces fit — vDPA, e-switch, OVS-DOCA (Phase 1a)

**For:** Yash · **Mentor:** Josh  
**Purpose:** Answer “where does vDPA fit?” and “who owns the e-switch?” without mixing this Blueprint with the wrong offload story.

---

## One-sentence model

**vDPA** is how the **guest** attaches (looks like normal virtio-net).  
**OVS-DOCA** on the **DPU Arm** is how we **program** forwarding policy.  
The **hardware e-switch** on the BF3 is what actually **forwards** packets once flows are offloaded.  
In **DPU mode**, the **DPU (Arm / ECPF)** owns the e-switch — not the x86 host.

---

## Layer cake (bottom → top)

| Layer | What it is | Who owns it | Blueprint role |
|-------|------------|-------------|----------------|
| **1. Hardware e-switch** | ASIC switch inside the BlueField | **DPU** in DPU mode (ECPF / Arm side) | Real datapath for established flows |
| **2. Representors** | Netdevs that *represent* VFs/SFs/ports to software | Visible on **Arm** (and related control plane) | Ports OVS attaches to / steers |
| **3. OVS-DOCA** | Open vSwitch using DOCA Flow to program HW | Runs on **DPU Arm** | Control plane + offload programming — **hero of this Blueprint** |
| **4. HW vDPA (DPDK + vhost-user)** | Virtio datapath acceleration for VMs | **Host** hypervisor (QEMU) + DPDK vdpa on VF | Guest attach model — **not** “the switch” |
| **5. Guest virtio-net** | Stock virtio NIC in the VM | Guest OS | Unchanged guest — no NVIDIA driver in guest |

```text
  [ Guest: stock virtio-net ]
            |  virtio
  [ Host: QEMU + vhost-user + DPDK mlx5 vDPA ]   ← attach HERE
            |
  [ DPU Arm: OVS-DOCA + VF representors ]        ← policy / offload programming
            |  programs
  [ BF3 hardware e-switch ]                      ← owned by DPU in DPU mode
            |
  [ Physical uplink ]
```

---

## Where vDPA fits (and where it does not)

### vDPA **is**

- A **VM NIC attachment** technology: guest keeps **stock virtio-net**.  
- The bridge between **hypervisor** (QEMU/vhost-user) and **accelerated virtio datapath** (DPDK mlx5 vDPA on a host VF).  
- Why we can talk about **live migration–friendly** virtio later (even though LM is deferred this cycle).  
- Part of **Phase 1a success**: prove the guest is on vDPA, **not** VF passthrough labeled as “offload.”

### vDPA is **not**

- Not the multi-tenant isolation policy engine (that’s OVS/OF rules → offloaded).  
- Not “OVS running in the guest.”  
- Not the same as **SR-IOV VF passthrough** (guest would bind a VF; different story; **rejected as primary** here).  
- Not proof of offload by itself — you still need **OVS-DOCA + HW offload evidence** (`docs/validation/offload-proof-contract.md`).

**Memory hook:** *vDPA = how the VM plugs in. OVS-DOCA = how the DPU decides. E-switch = where packets actually go.*

---

## Who owns the e-switch?

### In this Blueprint (BF3 **DPU mode**) — required

| Question | Answer |
|----------|--------|
| Who is e-switch manager? | **DPU Arm / ECPF** (embedded CPU ownership) |
| Can the x86 host take over e-switch like a normal NIC in switchdev? | **No** in DPU mode — host PF is not the e-switch owner; NVIDIA docs: host stays legacy from that POV; Arm PFs run switchdev-style model |
| Where does OVS run? | On the **Arm**, as **OVS-DOCA**, programming the HW via DOCA |
| Why does the Blueprint care? | “Offload to the DPU” means control + HW datapath live with the DPU, not host TC-flower theater |

Public reference (concepts): NVIDIA BlueField **Modes of Operation** (DPU/ECPF owns NIC resources and embedded switch); **DOCA Switching** (representors, e-switch, vDPA chapters). Exact CLI varies by DOCA/BFB pin — record what *your* lab shows in `docs/bom.md`.

### Contrast (so you don’t get confused in docs)

| Mode / story | E-switch ownership | Blueprint? |
|--------------|--------------------|------------|
| **DPU mode + OVS-DOCA** | DPU Arm | **Yes — primary** |
| Host-centric **switchdev + TC-flower / OVS-kernel** | Often told as host PF e-switch story | **Not** our publish path |
| **NIC mode** (BF looks like a normal NIC to host) | Not our DPU-offload story | Out of scope for 1a |

If lab docs say “enable switchdev on the Arm PF,” that can still be **true on the DPU side** and compatible with DPU mode — it does **not** mean “make the x86 host the e-switch owner.” When in doubt: **who runs OVS-DOCA?** → should be Arm. **Who programs offloaded flows?** → DOCA path from that OVS.

---

## Common confusion → crisp answers

| Intern question | Short answer |
|-----------------|--------------|
| “Is vDPA the offload?” | No. vDPA is the **guest attach**. Offload is **OVS-DOCA → HW e-switch**. |
| “Does the host own the e-switch?” | **Not in DPU mode.** DPU owns it. |
| “Why do I still see switchdev language?” | On BF3 DPU mode, Arm-side switchdev/representor model is normal plumbing — **don’t** reframe the Blueprint as host TC-flower. |
| “Can I just passthrough a VF to the VM?” | Faster sometimes, but **wrong guest model** for this Blueprint (breaks stock virtio-net / vDPA story). |
| “Where do I put OpenFlow rules?” | Against **OVS-DOCA** on the DPU (bridges/ports tied to representors / DOCA ports per your pin). |
| “What do I prove for Gate A?” | (1) DPU mode, (2) OVS-DOCA active, (3) guest on vDPA/virtio-net, (4) flows/counters show **HW offload**, (5) negative control. See V1 contract. |

---

## How this maps to your workplan

1. Confirm **DPU mode** + pin DOCA/BFB/host OS → `docs/bom.md`  
2. Bring up **OVS-DOCA** on Arm; VF representors as required  
3. Attach guest via **DPDK HW vDPA + vhost-user**  
4. Collect offload evidence per `docs/validation/offload-proof-contract.md`  

Mentor Wed office hours: bring `ovs-vsctl` / `dpctl` snippets if ownership still feels fuzzy — we’ll read them against this model.

---

## Related docs

- Topology sketch: [`architecture-1a.md`](architecture-1a.md)  
- Terms: [`../glossary.md`](../glossary.md)  
- Pass/fail: [`../validation/offload-proof-contract.md`](../validation/offload-proof-contract.md)  
- Non-goals (wrong path): [`../NON_GOALS.md`](../NON_GOALS.md)
