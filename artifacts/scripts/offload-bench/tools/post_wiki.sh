#!/usr/bin/env bash
# post_wiki.sh — copy the prepared pages into the GitHub wiki repo, show the changes, push after confirmation
set -euo pipefail
SRC=~/bp-003-ovs-working/new-chat-handover/wiki
DIR=~/bp003-wiki
URL=${WIKI_URL:-https://github.com/opiproject/bp-003-ovs-working.wiki.git}
if [ -d "$DIR/.git" ]; then git -C "$DIR" pull -q; else git clone -q "$URL" "$DIR"; fi
cp "$SRC"/*.md "$DIR"/
cd "$DIR"
git add -A
echo "== files that will change on the wiki"; git status --short
read -r -p "Push these wiki changes? (y/n) " a
[ "$a" = y ] || { echo "Not pushed; nothing changed on GitHub."; exit 0; }
git commit -q -m "Weeks 5-9, results summary, Week 4 correction, Home and sidebar update" \
  -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" \
  -m "Claude-Session: https://claude.ai/code/session_01HrBJ6dwtmpAiYbWBHSAyam"
git push -q && echo "Published: https://github.com/opiproject/bp-003-ovs-working/wiki"
