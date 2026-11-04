#!/usr/bin/env bash
# Install claude-kit into ~/.claude/. Backs up anything it would overwrite.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$DEST/agents"

if [ -f "$DEST/settings.json" ]; then
  cp "$DEST/settings.json" "$DEST/settings.json.bak-$STAMP"
  echo "backed up existing settings.json -> settings.json.bak-$STAMP"
fi
cp "$SRC/settings.json" "$DEST/settings.json"
echo "installed $DEST/settings.json"

for a in "$SRC"/agents/*.md; do
  n="$(basename "$a")"
  [ -f "$DEST/agents/$n" ] && cp "$DEST/agents/$n" "$DEST/agents/$n.bak-$STAMP"
  cp "$a" "$DEST/agents/$n"
  echo "installed $DEST/agents/$n"
done

echo
echo "Done. HOME=$HOME  DEST=$DEST"
echo "Copy CLAUDE.template.md into a repo as CLAUDE.md and fill it in."
echo "If a sandbox ignores ~/.claude, launch with: claude --settings $DEST/settings.json"
