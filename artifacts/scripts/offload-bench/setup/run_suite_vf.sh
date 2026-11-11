#!/usr/bin/env bash
# run_suite_vf.sh smoke|full — start the step-4 suite over the VFs, as opi, in tmux
set -euo pipefail
B=/home/opi/bench
chown opi:opi $B/bench_suite.sh $B/summarize_suite.py $B/pg_guest.sh $B/lib.sh
chmod +x $B/bench_suite.sh $B/summarize_suite.py
case "${1:-}" in
  smoke) R=1; M="tc";          L=suite_vf_smoke.log ;;
  full)  R=3; M="sw tc doca";  L=suite_vf.log ;;
  *) echo "usage: $0 smoke|full"; exit 2 ;;
esac
grep -q "bench_suite.sh" $B/CHANGELOG.md || echo "- $(date -u +%FT%TZ) added bench_suite.sh, summarize_suite.py, pg_guest.sh (step 4 suite)" >> $B/CHANGELOG.md
sudo -iu opi tmux new -s suite_$1 -d "cd ~/bench && DST=10.99.1.2 TNIC=vf0 ROUNDS=$R ./bench_suite.sh $M 2>&1 | tee ~/bench/$L"
echo "started '$1' (rounds=$R, modes=$M). Progress: grep -E 'done|finished|fail|cannot|not avail' $B/$L"
