#!/usr/bin/env bash
# Enforce centralized search — no raw grep -r in scripts.
# Why: Consistent .gitignore handling, easy to swap rg/grep.
# @see scripts/lib/search.sh
check_search() {
  local found=0
  while IFS= read -r file; do
    [[ "$file" == *"lib/search.sh" ]] && continue
    [[ "$file" == *"checks/search.sh" ]] && continue
    if grep -qn 'grep -r\|grep --recursive' "$file" 2>/dev/null; then
      print_error "$file: use scripts/lib/search.sh instead of grep -r"
      found=1
    fi
  done < <(find scripts -name '*.sh')
  return $found
}
