#!/usr/bin/env bash
# backup_raw.sh — pull dh5 results to a local cache, put 4 files per session into the repo
set -euo pipefail
CACHE=~/bp003-raw                                        # full raw copy, outside git
REPO=~/bp-003-ovs-working/docs/validation/results/sessions
OLD=~/bp-003-ovs-working/docs/validation/results/raw-dh5
mkdir -p "$CACHE" "$REPO"

# one-time: move the earlier loose copy out of the repo (nothing deleted)
if [ -d "$OLD" ]; then rsync -a "$OLD/" "$CACHE/" && mv "$OLD" "$CACHE/.moved_from_repo_$(date +%s)"; fi

# pull new results from dh5 (one password prompt; skips what is already here)
rsync -a root@172.22.1.5:/home/opi/bench/results/ "$CACHE/"

# pack each session not yet in the repo
for s in "$CACHE"/bulk_* "$CACHE"/suite_*; do
  [ -d "$s" ] || continue
  n=$(basename "$s"); o="$REPO/$n"
  [ -f "$o/raw.tar.gz" ] && continue
  mkdir -p "$o"
  tar -czf "$o/raw.tar.gz" -C "$CACHE" "$n" && tar -tzf "$o/raw.tar.gz" > /dev/null
  for f in summary.txt run.log params.txt; do [ -f "$s/$f" ] && cp "$s/$f" "$o/"; done
  echo "$n: $(find "$s" -type f | wc -l) raw files -> $(ls "$o" | wc -l) files in repo ($(du -h "$o/raw.tar.gz" | cut -f1) archive)"
done
