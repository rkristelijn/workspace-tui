#!/usr/bin/env bash
# Smart search utility - uses rg if available, falls back to grep
set -euo pipefail

PATTERN="$1"
shift
PATHS="${*:-src/ docs/}"

if command -v rg > /dev/null 2>&1; then
  rg --no-heading --line-number "$PATTERN" $PATHS 2>/dev/null || true
else
  grep -rn "$PATTERN" $PATHS 2>/dev/null || true
fi
