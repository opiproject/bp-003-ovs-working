# ~/bench/lib.sh — settings and helpers shared by every test script (sourced, not run)
VM1=192.168.123.253; VM2=192.168.123.254; DST=${DST:-10.99.0.2}; TNIC=${TNIC:-test0}
KEY=$HOME/.ssh/opi_bench; ARM=${ARM:-ubuntu@192.168.100.2}
PF0=enp13s0f0np0; PF1=enp13s0f1np1
VIRSH="virsh -c qemu:///system"
vm1() { ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 ubuntu@$VM1 "$@"; }
vm2() { ssh -i "$KEY" -o BatchMode=yes -o ConnectTimeout=5 ubuntu@$VM2 "$@"; }
arm() { ssh -o BatchMode=yes -o ConnectTimeout=8 "$ARM" "$@"; }
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$RUN/run.log"; }

snap() {  # snap <dir> <before|after> — drop/error counters at every hop
  local d=$1 t=$2 v n f
  for v in 1 2; do vm$v "echo '== nstat'; nstat -az; echo '== $TNIC'; ethtool -S $TNIC" > "$d/vm${v}_$t.txt" 2>&1; done
  { echo "== $PF0"; ethtool -S $PF0; echo "== $PF1"; ethtool -S $PF1
    for n in /sys/class/net/macvtap*; do echo "== ${n##*/}"; for f in $n/statistics/*; do echo "${f##*/} $(cat $f)"; done; done
  } > "$d/host_$t.txt" 2>&1
  arm 'for i in p0 p1 pf0hpf pf1hpf pf0vf0 pf1vf0; do echo "== $i"; ethtool -S $i; done; echo "== offload-stats"; sudo -n ovs-appctl dpctl/offload-stats-show' > "$d/arm_$t.txt" 2>&1
}

meta() {  # meta <dir> <mode> — everything needed to reproduce this run
  { echo "mode=$2 date=$(date -u +%FT%TZ) DST=$DST TNIC=$TNIC"; uname -r; cpupower frequency-info -p
    $VIRSH vcpupin bench-vm1; $VIRSH vcpupin bench-vm2; $VIRSH emulatorpin bench-vm1; $VIRSH emulatorpin bench-vm2
    vm1 'uname -r; iperf3 --version | head -1'; vm1 "ethtool -l $TNIC"; vm2 "ethtool -l $TNIC"; } > "$1/meta.txt" 2>&1
  arm 'sudo -n /usr/local/sbin/opi_arm_mode.sh status' >> "$1/meta.txt" 2>&1
}
