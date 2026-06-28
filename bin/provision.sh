#!/usr/bin/env bash
# provision.sh — idempotent, fast session-start provisioning for ephemeral
# environments (notably Claude Code on the web, where the container is
# reclaimed and the repo is re-cloned for each session).
#
# It restores everything that is NOT committed to git but is needed to use the
# vault's full feature set:
#   1. Skills registered into ~/.claude/skills/  (always — cheap)
#   2. Transport detection                       (only if transport.json missing)
#   3. Methodology mode = generic                (only if mode.json missing)
#   4. Hybrid-retrieval index (BM25, local)      (only if the index is missing)
#
# DragonScale core state (address counter, tiling thresholds, legacy-pages) is
# committed to git, so it survives a fresh clone and needs no action here.
#
# Each step is guarded so warm containers re-run almost instantly. The heavy
# retrieval build runs only on a fresh container (when the BM25 index is gone).
#
# Usage: bash bin/provision.sh
set -uo pipefail   # NOT -e: a single optional step must never abort the rest

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
META=".vault-meta"

# 1. Skills — always (idempotent, cheap)
[ -x bin/register-skills.sh ] && bash bin/register-skills.sh

# 2. Transport detection — only if not yet recorded
if [ ! -f "$META/transport.json" ] && [ -x scripts/detect-transport.sh ]; then
  bash scripts/detect-transport.sh >/dev/null 2>&1 && echo "✓ transport detected"
fi

# 3. Methodology mode — only if unset (generic is the default; explicit is clearer)
if [ ! -f "$META/mode.json" ] && [ -x bin/setup-mode.sh ]; then
  bash bin/setup-mode.sh --mode generic --no-seed >/dev/null 2>&1 && echo "✓ mode=generic"
fi

# 4. Hybrid retrieval — rebuild only when the index is absent (fresh container).
#    Fully local: --no-llm forces synthetic prefixes, no data egress, no ollama.
if [ ! -f "$META/bm25/index.json" ] && [ -x bin/setup-retrieve.sh ]; then
  echo "Building local retrieval index (one-time per container)…"
  bash bin/setup-retrieve.sh --no-llm >/dev/null 2>&1 && echo "✓ retrieval index built"
fi

echo "✓ provision complete"
