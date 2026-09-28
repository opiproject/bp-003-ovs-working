#!/usr/bin/env bash
# opi_host_vms.sh — create/destroy the two benchmark VMs ON HOST dh5.
# Usage:  sudo ./opi_host_vms.sh setup | teardown | status
#
# Topology (traffic crosses the BF3 eswitch and the wire, never terminates on the Arm):
#   opi-bench-vm1 --macvtap--> PF0 -> [BF3 ovsbr1: pf0hpf <-> p0] -> switch
#   switch -> [BF3 ovsbr2: p1 <-> pf1hpf] -> PF1 --macvtap--> opi-bench-vm2
# Each VM also has a NIC on libvirt 'default' (virbr0) for SSH from the host.
# Test IPs: 10.99.0.1 (vm1) / 10.99.0.2 (vm2). Only touches VMs named opi-bench-*.
set -euo pipefail

PF0="${PF0:-enp13s0f0np0}"
PF1="${PF1:-enp13s0f1np1}"
DIR=/opt/opi_experiment/vms
IMG_URL="${IMG_URL:-https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img}"
BASE="$DIR/base-jammy.img"
KEY=/root/.ssh/id_ed25519
MEM="${MEM:-4096}"; CPUS="${CPUS:-4}"
SSHO=(-o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i "$KEY")

[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }
log() { echo "[$(date -u +%FT%TZ)] $*"; }

teardown() {
  for i in 1 2; do
    n=opi-bench-vm$i
    if virsh dominfo "$n" >/dev/null 2>&1; then
      log "removing $n"
      virsh destroy "$n" >/dev/null 2>&1 || true
      virsh undefine "$n" --nvram >/dev/null 2>&1 || virsh undefine "$n" >/dev/null 2>&1 || true
    fi
    rm -f "$DIR/vm$i.qcow2" "$DIR/seed$i.iso"
  done
  rm -f "$DIR/vms.env"
  log "teardown done (base image kept at $BASE)"
}

status() {
  virsh list --all | grep -E 'Name|opi-bench' || true
  [[ -f $DIR/vms.env ]] && cat "$DIR/vms.env"
}

mgmt_ip() {  # $1 domain, $2 mac
  virsh domifaddr "$1" --source lease 2>/dev/null | awk -v m="$2" '$2==m{split($4,a,"/");print a[1]}'
}

setup() {
  trap 'log "ERROR — rolling back"; teardown; exit 1' ERR

  for pf in "$PF0" "$PF1"; do
    ip link show "$pf" >/dev/null || { log "PF $pf not found (set PF0/PF1)"; exit 1; }
    ip link set "$pf" up
  done

  log "packages"
  need=()
  for c in virt-install:virtinst cloud-localds:cloud-image-utils qemu-img:qemu-utils virsh:libvirt-clients; do
    command -v "${c%%:*}" >/dev/null || need+=("${c##*:}")
  done
  dpkg -s qemu-system-x86 >/dev/null 2>&1 || need+=(qemu-system-x86)
  dpkg -s libvirt-daemon-system >/dev/null 2>&1 || need+=(libvirt-daemon-system)
  if ((${#need[@]})); then apt-get update -qq; DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${need[@]}"; fi
  systemctl enable --now libvirtd >/dev/null 2>&1 || true
  virsh net-info default >/dev/null 2>&1 || { log "libvirt 'default' network missing"; exit 1; }
  virsh net-start default >/dev/null 2>&1 || true
  virsh net-autostart default >/dev/null 2>&1 || true

  mkdir -p "$DIR"
  [[ -f $KEY ]] || ssh-keygen -q -t ed25519 -N '' -f "$KEY"
  [[ -f $BASE ]] || { log "downloading cloud image"; curl -fsSL -o "$BASE.part" "$IMG_URL"; mv "$BASE.part" "$BASE"; }

  : > "$DIR/vms.env"
  for i in 1 2; do
    n=opi-bench-vm$i
    virsh dominfo "$n" >/dev/null 2>&1 && { log "$n already exists — run teardown first"; exit 1; }
    pf=$([[ $i == 1 ]] && echo "$PF0" || echo "$PF1")
    mmac=52:54:00:aa:00:0$i
    tmac=52:54:00:99:00:0$i

    cat > "$DIR/user-data$i" <<EOF
#cloud-config
hostname: $n
ssh_pwauth: false
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat "$KEY.pub")
package_update: true
packages: [iperf3, sysstat]
EOF
    cat > "$DIR/network-config$i" <<EOF
version: 2
ethernets:
  mgmt:
    match: {macaddress: "$mmac"}
    set-name: mgmt0
    dhcp4: true
  test:
    match: {macaddress: "$tmac"}
    set-name: test0
    dhcp4: false
    addresses: [10.99.0.$i/24]
EOF
    cloud-localds --network-config="$DIR/network-config$i" "$DIR/seed$i.iso" "$DIR/user-data$i"
    qemu-img create -q -f qcow2 -F qcow2 -b "$BASE" "$DIR/vm$i.qcow2" 20G

    log "creating $n (test NIC macvtap on $pf)"
    virt-install --name "$n" --memory "$MEM" --vcpus "$CPUS" --import \
      --osinfo detect=on,require=off \
      --disk "path=$DIR/vm$i.qcow2,bus=virtio" \
      --disk "path=$DIR/seed$i.iso,device=cdrom" \
      --network "network=default,mac=$mmac,model=virtio" \
      --network "type=direct,source=$pf,source_mode=bridge,mac=$tmac,model=virtio" \
      --graphics none --noautoconsole >/dev/null
  done

  for i in 1 2; do
    n=opi-bench-vm$i; ip=""
    log "waiting for $n mgmt IP"
    for _ in $(seq 1 90); do ip=$(mgmt_ip "$n" 52:54:00:aa:00:0$i); [[ -n $ip ]] && break; sleep 2; done
    [[ -n $ip ]] || { log "$n got no mgmt IP"; false; }
    for _ in $(seq 1 60); do ssh "${SSHO[@]}" ubuntu@"$ip" true 2>/dev/null && break; sleep 3; done
    log "$n at $ip — waiting for cloud-init"
    ssh "${SSHO[@]}" ubuntu@"$ip" 'cloud-init status --wait >/dev/null; command -v iperf3 >/dev/null'
    echo "VM${i}_IP=$ip" >> "$DIR/vms.env"
  done

  # shellcheck disable=SC1091
  source "$DIR/vms.env"
  log "data-path check: vm1 -> 10.99.0.2 (through the BF3 eswitch + wire)"
  if ssh "${SSHO[@]}" ubuntu@"$VM1_IP" 'ping -c 5 -W 2 10.99.0.2'; then
    log "OK — VMs ready. IPs saved in $DIR/vms.env"
  else
    log "VMs are up but 10.99.0.x does not ping. Check on the Arm: ovs-vsctl show, p0/p1 link, pf0hpf/pf1hpf up."
    log "(not rolling back — VMs left running for debugging)"
  fi
  trap - ERR
}

case "${1:-}" in
  setup) setup ;;
  teardown) teardown ;;
  status) status ;;
  *) echo "usage: $0 setup|teardown|status"; exit 2 ;;
esac
