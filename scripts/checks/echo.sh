#!/usr/bin/env bash
set -euo pipefail

FOUND=0

# Check scripts should not use raw echo/printf (use lib/ui.sh)
# Exception: checks/ scripts output to stdout for the runner to capture
# Only enforce on git/ scripts that do UI output
for script in scripts/git/*.sh; do
  [[ ! -f "$script" ]] && continue
  [[ "$script" == *"pre-commit.sh" ]] && continue
  if grep -n "^[[:space:]]*echo \|^[[:space:]]*printf " "$script" 2>/dev/null | grep -qv 'source\|#'; then
    echo "$script: use lib/ui.sh instead of raw echo/printf"
    FOUND=1
  fi
done

exit $FOUND
