# Blueprint 003 — Stakeholder Map

Who decides, who executes, who unblocks. Keep asks on the right lane.

---

## Roles

| Role | Who | Owns | Does not own |
|------|-----|------|--------------|
| **Sponsor / mentor** | Josh Brooks (WTIT), OPI GB | Direction, scope reopen, publish bar, partner posture, TSC narrative | Day-to-day lab grind, writing every doc line |
| **Execution** | LFX intern | Build, validate, draft docs/IaC, PRs, evidence | Changing locked stack; speaking for GB |
| **LF / OPI process** | TSC liaison (e.g. Sridhar Rao) | Intern program, AI tokens, org access, publish-repo confirmation | Technical design of OVS-DOCA path |
| **Lab access** | OPI Lab admin (VPN historically via lab contact) | VPN, node assignment, reservations | Blueprint content |
| **Platform partner** | Red Hat (OpenShift Virt, OVN-K, RHEL) | Guidance, entitlements path when engaged | Owning WTIT delivery timeline |
| **Reference silicon/tooling** | NVIDIA (BF3, DOCA, DPF) | Public software/docs; not OPI member governance | OPI Blueprint ownership |
| **Contributing integrator** | WorldTech IT | Leads delivery through publish; attribution | Claiming NVIDIA membership; sole long-term maintainer (see #9) |
| **Post-intern maintenance** | OPI community / TSC process | Own Blueprint after LFX term (decision #9) | Day-to-day build during internship |


---

## Decision vs execution split

| Class | Examples | Decider | Executor |
|-------|----------|---------|----------|
| **Direction** | v1 publish bar; persona; non-goals; branding; Track 2 reopen | Sponsor | — |
| **Technical contract** | Offload-proof counters; harness choice; pin bumps when broken | Sponsor (accept) | Intern proposes |
| **Build** | Stand up 1a/1b; write guide; capture results | — | Intern |
| **Access** | GitHub org, lab VPN, entitlements | LF/lab/RH/NVIDIA as applicable | Intern requests; sponsor escalates |
| **Publish** | Target repo, ID reconcile, TSC showcase slot | Sponsor + LF maintainers | Intern prepares PR |

---

## Escalation

1. **Access / lab** → lab admin → sponsor if stale >3 business days.  
2. **Design ambiguity** (is this offload?) → sponsor technical accept.  
3. **Scope creep** → point at [`NON_GOALS.md`](NON_GOALS.md); require S-decision.  
4. **Partner commit** (RH cluster, NVIDIA support) → sponsor only.

---

## Communications (public project)

- Status for TSC: from `docs/` + `artifacts/` only.  
- Mentorship cadence: weekly; decisions recorded in [`SPONSOR_DECISIONS.md`](SPONSOR_DECISIONS.md) or PR.  
- No board/personal email in git.
