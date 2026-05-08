#!/usr/bin/env bash
# Centralized search — all file content searches go through here.
#
# Why: Single point to swap search backends (rg vs grep) and ensure
# .gitignore is respected. Prevents inconsistent grep flags across scripts.
#
# Usage: bash scripts/lib/search.sh 'pattern' [paths...]
# Default paths: src/ docs/
#
# @see scripts/checks/search.sh (enforces usage of this file)
set -euo pipefail

PATTERN="$1"
shift
PATHS="${*:-src/ docs/}"

# Prefer ripgrep: faster, respects .gitignore by default
if command -v rg > /dev/null 2>&1; then
  rg --no-heading --line-number "$PATTERN" $PATHS 2>/dev/null || true
else
  grep -rn "$PATTERN" $PATHS 2>/dev/null || true
fi
