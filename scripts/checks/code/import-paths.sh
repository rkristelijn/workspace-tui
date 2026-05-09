#!/usr/bin/env bash
# Check for deep relative imports — enforce path aliases
# @see docs/adr/011-020/016-typescript-path-aliases.md

check_import_paths() {
  local found=0
  
  # Find deep relative imports (../../..)
  while IFS= read -r match; do
    print_error "$match"
    found=1
  done < <(grep -rn "\.\./\.\./\.\." src/ --include="*.ts" 2>/dev/null || true)
  
  [[ $found -eq 0 ]] && return 0
  
  print_error "Use path aliases: @/data/types not ../../../data/types"
  return 1
}
