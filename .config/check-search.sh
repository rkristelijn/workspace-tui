#!/usr/bin/env bash
# Check for direct grep/find usage instead of search.sh
# All searches must go through centralized search utility

set -euo pipefail

FOUND=0
VIOLATIONS=()

# Check for grep usage in scripts (except search.sh and this check)
while IFS= read -r file; do
  [[ "$file" == *"search.sh" ]] && continue
  [[ "$file" == *"check-search.sh" ]] && continue
  [[ "$file" == *"ui.sh" ]] && continue
  
  # Allow grep for non-file-content searches (like checking variables)
  # Block: grep -r, grep --recursive, grep with file arguments
  if grep -n 'grep -r\|grep --recursive' "$file" 2>/dev/null; then
    VIOLATIONS+=("$file: use .config/search.sh instead of grep -r")
    FOUND=1
  fi
done < <(find .config -name '*.sh')

if [[ $FOUND -eq 1 ]]; then
  for violation in "${VIOLATIONS[@]}"; do
    printf "%s\n" "$violation" >&2
    printf "%s\n" "  Use: bash .config/search.sh 'pattern' [paths]" >&2
  done
  exit 1
fi
