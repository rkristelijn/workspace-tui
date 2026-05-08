#!/usr/bin/env bash
set -euo pipefail

EMOJI_FILES=$(bash scripts/lib/search.sh '[\x{1F300}-\x{1F9FF}]' 2>/dev/null | cut -d: -f1 | sort -u | grep -v "checks/emoji.sh" || true)

if [[ -n "$EMOJI_FILES" ]]; then
  echo "Emoji found in: $EMOJI_FILES"
  exit 1
fi
