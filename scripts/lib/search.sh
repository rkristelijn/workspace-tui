#!/usr/bin/env bash
# Centralized search — all file content searches go through here.
#
# Why: Single point to swap search backends (rg vs grep) and ensure
# .gitignore is respected. Prevents inconsistent grep flags across scripts.
#
# Usage: search_files 'pattern' [paths...]
# Default paths: src/ docs/
#
# @see docs/adr/001-010/008-centralized-search.md

search_files() {
  local pattern="$1"
  shift
  local paths="${*:-src/ docs/}"

  if command -v rg > /dev/null 2>&1; then
    rg --no-heading --line-number "$pattern" $paths 2>/dev/null || true
  else
    find $paths -type f \( -name '*.ts' -o -name '*.md' -o -name '*.sh' \) -exec grep -Hn "$pattern" {} + 2>/dev/null || true
  fi
}

# Allow direct invocation: bash scripts/lib/search.sh 'pattern' [paths...]
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  search_files "$@"
fi
