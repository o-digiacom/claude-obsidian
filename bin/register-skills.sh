#!/usr/bin/env bash
# Register the claude-obsidian skills with the Claude Code harness.
#
# WHY: In some environments (notably Claude Code on the web), the harness
# discovers user-invocable skills only under ~/.claude/skills/. Skills shipped
# in this repo under skills/ — and skills installed via `claude plugin install`
# (which land in the plugin cache) — are NOT surfaced there. This script copies
# the repo's skills into ~/.claude/skills/ so that /wiki and the other skills
# become available. It is idempotent: safe to run on every session start.
#
# Usage: bash bin/register-skills.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/skills"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"

mkdir -p "$DEST"

count=0
for dir in "$SRC"/*/; do
  [ -f "${dir}SKILL.md" ] || continue
  name="$(basename "$dir")"
  target="$DEST/$name"
  # Refresh: remove any prior copy/symlink, then copy the full skill dir
  # (SKILL.md + references/) as real files so the skill scanner discovers it.
  rm -rf "$target"
  cp -R "$dir" "$target"
  count=$((count + 1))
done

echo "✓ Registered $count claude-obsidian skill(s) into $DEST"
