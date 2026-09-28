#!/usr/bin/env bash
# opi_arm_mode.sh — switch the BF3 Arm-side OVS between benchmark modes.
# Runs ON THE BF3 ARM, as root (installed to /usr/local/sbin by opi_arm_prep.sh).
#
#   sw     kernel datapath, hw-offload=false   (L2: Arm software forwarding)
#   tc     kernel datapath, hw-offload=true    (L3: tc/ASAP2 eswitch offload)
#   doca   OVS-DOCA: netdev bridges, dpdk ports, doca-init + hw-offload (L4)
#   status print current mode, bridges, port types
#
# Bridges and their ports are discovered from the live config, so it works
# whatever the 3.5 image named them (default: ovsbr1/ovsbr2 with p0/p1,
# pf0hpf/pf1hpf and the SF representors).
set -euo pipefail

MODE="${1:-status}"
HUGE_MB="${HUGE_MB:-2048}"          # hugepage memory for OVS-DOCA
LOG=/opt/opi_experiment/arm_mode.log
mkdir -p /opt/opi_experiment

[[ $EUID -eq 0 ]] || { echo "run as root (sudo)"; exit 1; }

if systemctl cat openvswitch-switch >/dev/null 2>&1; then
  SVC=openvswitch-switch
else
  SVC=openvswitch
fi

log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG"; }

wait_ovs() {
  for _ in $(seq 1 30); do
    ovs-vsctl --timeout=5 show >/dev/null 2>&1 && return 0
    sleep 1
  done
  log "ERROR: ovs-vswitchd did not come back after restart"; exit 1
}

restart_ovs() {
  log "restarting $SVC"
  systemctl restart "$SVC"
  wait_ovs
}

oc_get() { ovs-vsctl --if-exists get Open_vSwitch . "other_config:$1" 2>/dev/null | tr -d '"' || true; }

status() {
  echo "service        : $SVC ($(systemctl is-active "$SVC"))"
  echo "hw-offload     : $(oc_get hw-offload)"
  echo "doca-init      : $(oc_get doca-init)"
  echo "doca_initialized: $(ovs-vsctl get Open_vSwitch . doca_initialized 2>/dev/null || echo n/a)"
  for br in $(ovs-vsctl list-br); do
    echo "bridge $br datapath_type=$(ovs-vsctl get bridge "$br" datapath_type)"
    for p in $(ovs-vsctl list-ports "$br"); do
      echo "    $p type=$(ovs-vsctl get interface "$p" type)"
    done
  done
  ovs-appctl dpif/show 2>/dev/null | head -20 || true
}

# rebuild every bridge with the given datapath type; porttype "dpdk" or ""
rebuild_bridges() {
  local dp="$1" ptype="$2" br p
  declare -A PORTS
  for br in $(ovs-vsctl list-br); do
    PORTS[$br]="$(ovs-vsctl list-ports "$br" | tr '\n' ' ')"
  done
  [[ ${#PORTS[@]} -gt 0 ]] || { log "ERROR: no bridges found"; exit 1; }
  for br in "${!PORTS[@]}"; do
    log "rebuild $br datapath=$dp ports=[${PORTS[$br]}] type=${ptype:-system}"
    ovs-vsctl --if-exists del-br "$br"
    ovs-vsctl add-br "$br" -- set bridge "$br" datapath_type="$dp"
    for p in ${PORTS[$br]}; do
      if [[ -n "$ptype" ]]; then
        ovs-vsctl add-port "$br" "$p" -- set Interface "$p" type="$ptype"
      else
        ovs-vsctl add-port "$br" "$p"
      fi
    done
  done
}

any_netdev_bridge() {
  for br in $(ovs-vsctl list-br); do
    [[ "$(ovs-vsctl get bridge "$br" datapath_type)" == "netdev" ]] && return 0
  done
  return 1
}

PRE_DOCA_DB=/opt/opi_experiment/pre_doca_conf.db
DB=$(readlink -f /etc/openvswitch/conf.db)   # real file; /etc path is a symlink on this image

to_kernel() {   # $1 = true|false for hw-offload
  if [[ "$(oc_get doca-init)" == "true" ]] || any_netdev_bridge; then
    # Removing doca-init while netdev/dpdk bridges exist crashes ovs-vswitchd on
    # restart (assert in conntrack_offload_config, seen on DOCA 3.5). So instead of
    # editing the live config, restore the DB snapshot taken before entering doca mode.
    [[ -f $PRE_DOCA_DB ]] || { log "ERROR: no $PRE_DOCA_DB snapshot — restore a backup/<ts>/conf.db by hand"; exit 1; }
    log "leaving OVS-DOCA mode: restoring pre-doca DB snapshot"
    systemctl stop "$SVC" || true
    cat "$PRE_DOCA_DB" > "$DB"            # write through, never copy the symlink
    # netdev datapath leaves persistent tap devices named after each bridge; they
    # block the kernel datapath from creating its internal port ("File exists")
    for br in $(ip -o link show type tun 2>/dev/null | awk -F': ' '{print $2}' | cut -d@ -f1); do
      if ovs-vsctl --no-wait br-exists "$br" 2>/dev/null; then log "removing stale tap $br"; ip link del "$br" || true; fi
    done
    systemctl reset-failed ovs-vswitchd ovsdb-server "$SVC" 2>/dev/null || true
    systemctl start "$SVC"
    wait_ovs
  fi
  ovs-vsctl set Open_vSwitch . other_config:hw-offload="$1"
  restart_ovs
}

setup_hugepages() {
  local sz pages cur
  sz=$(awk '/Hugepagesize/{print $2}' /proc/meminfo)       # kB
  pages=$(( HUGE_MB * 1024 / sz ))
  cur=$(cat "/sys/kernel/mm/hugepages/hugepages-${sz}kB/nr_hugepages")
  if (( cur < pages )); then
    log "hugepages: ${sz}kB x $pages (was $cur)"
    echo "$pages" > "/sys/kernel/mm/hugepages/hugepages-${sz}kB/nr_hugepages"
  fi
  mountpoint -q /dev/hugepages || mount -t hugetlbfs hugetlbfs /dev/hugepages
  grep -E 'HugePages_(Total|Free)' /proc/meminfo
}

to_doca() {
  if [[ "$(oc_get doca-init)" != "true" ]] && ! any_netdev_bridge; then
    ovs-vsctl --no-wait set Open_vSwitch . other_config:hw-offload=true
    systemctl stop "$SVC"; cat "$DB" > "$PRE_DOCA_DB"; systemctl start "$SVC"; wait_ovs
    [[ -s $PRE_DOCA_DB && ! -L $PRE_DOCA_DB ]] || { log "ERROR: snapshot failed"; exit 1; }
    log "saved pre-doca DB snapshot to $PRE_DOCA_DB"
  fi
  setup_hugepages
  ovs-vsctl --no-wait set Open_vSwitch . other_config:doca-init=true
  ovs-vsctl --no-wait set Open_vSwitch . other_config:hw-offload=true
  restart_ovs
  rebuild_bridges netdev dpdk
  local di
  di=$(ovs-vsctl get Open_vSwitch . doca_initialized 2>/dev/null || echo false)
  [[ "$di" == "true" ]] || log "WARNING: doca_initialized=$di — check /var/log/openvswitch/ovs-vswitchd.log"
}

case "$MODE" in
  sw)     log "mode -> sw";   to_kernel false ;;
  tc)     log "mode -> tc";   to_kernel true ;;
  doca)   log "mode -> doca"; to_doca ;;
  status) ;;
  *) echo "usage: $0 {sw|tc|doca|status}"; exit 2 ;;
esac
status
