#!/usr/bin/env bash
# Enforce centralized search — no raw grep -r in scripts.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_search() {
  source scripts/lib/skip.sh
  should_skip "search" && return 0

  local found=0
  while IFS= read -r file; do
    [[ "$file" == *"lib/search.sh" ]] && continue
    [[ "$file" == *"quality/search.sh" ]] && continue
    if grep -qn 'grep -r\|grep --recursive' "$file" 2>/dev/null; then
      print_error "$file: use scripts/lib/search.sh instead of grep -r"
      found=1
    fi
  done < <(find scripts -name '*.sh')
  return $found
}
