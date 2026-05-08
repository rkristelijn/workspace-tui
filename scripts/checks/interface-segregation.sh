#!/usr/bin/env bash
# Providers use Interface Segregation — implement only what they support.
# No god-class with all methods. Each capability (calendar, email, tasks)
# is a separate interface, providers compose only what they offer.
# @see docs/adr/005-interface-segregation.md
check_interface_segregation() {
  local found=0
  # Flag files with >3 class methods (sign of god-class)
  while IFS= read -r file; do
    local methods; methods=$(grep -c '^\s*async\s\|^\s*public\s\|^\s*private\s' "$file" 2>/dev/null || echo 0)
    if [[ "$methods" -gt 10 ]]; then
      print_error "$file: $methods methods — split into smaller classes"
      found=1
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  return $found
}
