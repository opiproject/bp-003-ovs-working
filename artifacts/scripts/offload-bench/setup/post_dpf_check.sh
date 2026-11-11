#!/usr/bin/env bash
# post_dpf_check.sh — read-only: DPF's record of what it did, and the card's state now
C=/home/opi/bench/state/crash_20261111; mkdir -p $C
echo "== DPF's view of the DPU"
kubectl get dpu -A -o wide
kubectl get dpu -n dpf-operator-system dh5-bluefield-3 -o yaml > $C/dpf_dpu.yaml 2>&1
echo "== recent DPF events for this DPU (events expire after ~1 h, so saved now)"
kubectl get events -n dpf-operator-system --sort-by=.lastTimestamp 2>&1 | grep -iE "dh5|bluefield|dpu" | tee $C/dpf_events.txt | tail -20
echo "== provisioning controller logs: when did it act on dh5? (full logs saved)"
for id in $(crictl ps | awk '/dpf-provisioning-controller-manager/{print $1}'); do
  crictl logs --timestamps $id > $C/dpf_provisioning_$id.log 2>&1
  echo "-- $id: first lines mentioning dh5 / reset / install"
  grep -iE "dh5|bluefield-3" $C/dpf_provisioning_$id.log | grep -iE "reset|reboot|install|phase|initial|power|creat" | head -15
done
echo "== card firmware settings (read from the host; are the emulation settings still there?)"
mlxconfig -d 0000:0d:00.0 q 2>&1 | grep -E "VIRTIO_NET_EMULATION_(ENABLE|NUM_PF|NUM_VF)|PER_PF_NUM_SF|PF_TOTAL_SF|SRIOV_EN|NUM_OF_VFS"
echo "== host side"
ip -br link show enp13s0f0np0; ip -br link show enp13s0f1np1
lspci -nnD -d 1af4:
virsh -c qemu:///system list --all
chown -R opi:opi $C; echo "saved in $C"
