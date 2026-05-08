#!/usr/bin/env bash
set -euo pipefail

FOUND=0

# No grep -r in scripts (except lib/search.sh and this check)
while IFS= read -r file; do
  [[ "$file" == *"lib/search.sh" ]] && continue
  [[ "$file" == *"checks/search.sh" ]] && continue
  if grep -qn 'grep -r\|grep --recursive' "$file" 2>/dev/null; then
    echo "$file: use scripts/lib/search.sh instead of grep -r"
    FOUND=1
  fi
done < <(find scripts -name '*.sh')

exit $FOUND
