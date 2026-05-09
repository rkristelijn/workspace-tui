#!/usr/bin/env bash
# Providers use Interface Segregation — implement only what they support.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_interface_segregation() {
  source scripts/lib/skip.sh
  should_skip "interface-segregation" && return 0

  local found=0
  while IFS= read -r file; do
    local methods; methods=$(grep -c '^\s*async\s\|^\s*public\s\|^\s*private\s' "$file" 2>/dev/null || echo 0)
    if [[ "$methods" -gt 10 ]]; then
      print_error "$file: $methods methods — split into smaller classes"
      found=1
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  return $found
}
