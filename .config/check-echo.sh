#!/usr/bin/env bash
set -euo pipefail

source .config/ui.sh

# Check for direct echo/printf usage (except ui.sh and autofix)
FOUND=0

for script in .config/*.sh; do
  [[ "$script" == ".config/ui.sh" ]] && continue
  [[ "$script" == ".config/check-echo.sh" ]] && continue
  [[ "$script" == ".config/autofix-echo.sh" ]] && continue
  
  # Check for echo/printf (exclude command substitution)
  if grep -n "echo \|printf " "$script" 2>/dev/null | grep -v '\$(echo\|printf'; then
    print_error "Found output in $script"
    print_info "Use ui.sh: print_error, print_warning, print_line, print_info" 2
    FOUND=1
  fi
done

if [[ $FOUND -eq 1 ]]; then
  exit 1
fi

