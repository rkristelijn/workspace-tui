#!/usr/bin/env bash
set -euo pipefail

# Check for direct echo usage in logic scripts (except ui.sh)
FOUND=0

for script in .config/*.sh; do
  # Skip ui.sh and this check script
  [[ "$script" == ".config/ui.sh" ]] && continue
  [[ "$script" == ".config/check-echo.sh" ]] && continue
  
  # Check for echo statements
  if grep -n "echo " "$script" 2>/dev/null; then
    echo "ERROR: Found 'echo' in $script"
    echo "  Use ui.sh functions instead (print_step, print_error, etc.)"
    FOUND=1
  fi
done

if [[ $FOUND -eq 1 ]]; then
  exit 1
fi
