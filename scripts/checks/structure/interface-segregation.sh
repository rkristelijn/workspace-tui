#!/usr/bin/env bash
# Providers use Interface Segregation — no god classes with too many methods.
# @see docs/adr/001-010/003-interface-segregation.md

check_interface_segregation() {
  source scripts/lib/skip.sh
  should_skip "interface-segregation" && return 0

  local found=0
  while IFS= read -r file; do
    local methods
    methods=$(grep -c '^\s*async\s\|^\s*public\s\|^\s*private\s' "$file" 2>/dev/null || echo "0")
    methods="${methods//[^0-9]/}"
    [[ -z "$methods" ]] && methods=0
    if (( methods > 10 )); then
      print_error "$file: $methods methods — split into smaller classes"
      found=1
    fi
  done < <(find src -name '*.ts' ! -name '*.test.ts' 2>/dev/null)
  return $found
}
