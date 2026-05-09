#!/usr/bin/env bash
# Enforce centralized search — no raw grep -r in scripts.
# Why: Consistent .gitignore handling, easy to swap rg/grep.
# Skip config from .config/checks-skip.json
# @see scripts/lib/search.sh

check_search() {
  # Check if skip is enabled
  local skip_config=".config/checks-skip.json"
  if [[ -f "$skip_config" ]]; then
    local skip_enabled; skip_enabled=$(jq -r '.skip.search.enabled // false' "$skip_config" 2>/dev/null)
    if [[ "$skip_enabled" == "true" ]]; then
      local reason; reason=$(jq -r '.skip.search.reason // "No reason"' "$skip_config" 2>/dev/null)
      echo "SKIP: $reason"
      return 0
    fi
  fi
  
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
