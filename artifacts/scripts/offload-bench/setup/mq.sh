#!/usr/bin/env bash
set -euo pipefail
source ~/bench/lib.sh

# 1. backup + changelog
BK=~/bench/state/before_mq_$(date -u +%Y%m%dT%H%M%SZ); mkdir -p "$BK"
for vm in bench-vm1 bench-vm2; do $VIRSH dumpxml --inactive $vm > $BK/$vm.xml; done
cp ~/bench/lib.sh $BK/
echo "- $(date -u +%FT%TZ) multiqueue: macvtap queues=4; emulatorpin vm1 18,20,22,24 vm2 26,28,30,32; staying on 22.04/6.8 for steps 1-4. Undo: virsh define $BK/<vm>.xml" >> ~/bench/CHANGELOG.md

# 2. shut down and wait until both are off
for vm in bench-vm1 bench-vm2; do $VIRSH shutdown $vm; done
while $VIRSH list --name | grep -q bench-vm; do sleep 2; done

# 3. 4 queues on the macvtap NIC, wider emulator pins
virt-xml -c qemu:///system bench-vm1 --edit mac=52:54:00:99:00:01 --network driver.name=vhost,driver.queues=4
virt-xml -c qemu:///system bench-vm2 --edit mac=52:54:00:99:00:02 --network driver.name=vhost,driver.queues=4
$VIRSH emulatorpin bench-vm1 18,20,22,24 --config
$VIRSH emulatorpin bench-vm2 26,28,30,32 --config
grep -q "ethtool -l test0" ~/bench/lib.sh || sed -i "s#iperf3 --version | head -1'; }#iperf3 --version | head -1'; vm1 'ethtool -l test0'; vm2 'ethtool -l test0'; }#" ~/bench/lib.sh

# 4. start and wait for SSH
for vm in bench-vm1 bench-vm2; do $VIRSH start $vm; done
until vm1 true 2>/dev/null && vm2 true 2>/dev/null; do sleep 3; done

# 5. enable 4 queues in the guests and read back the current count
for f in vm1 vm2; do $f 'sudo ethtool -L test0 combined 4 >/dev/null 2>&1 || true'; done
q1=$(vm1 "ethtool -l test0 | awk '/Current/{c=1} c&&/Combined/{print \$2}'")
q2=$(vm2 "ethtool -l test0 | awk '/Current/{c=1} c&&/Combined/{print \$2}'")
echo "queues: vm1=$q1 vm2=$q2"
[ "$q1" = 4 ] && [ "$q2" = 4 ] || { echo "Not 4 queues, benchmark not started."; exit 1; }
vm1 "ping -c 2 -W 2 $DST"

# 6. benchmark in tmux
tmux new -s bench -d "cd ~/bench && ROUNDS=5 ./bench_bulk.sh sw tc doca 2>&1 | tee ~/bench/bulk_mq.log"
echo "Benchmark running. Watch with: tmux attach -t bench   (detach: Ctrl+B then D)"
