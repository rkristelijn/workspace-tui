#!/usr/bin/env bash
# Types belong with their module, not in separate types.ts files.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_types_colocation() {
  source scripts/lib/skip.sh
  should_skip "types-colocation" && return 0

  local found=0
  while IFS= read -r file; do
    print_error "$file: colocate types in their module file"
    found=1
  done < <(find src -name 'types.ts' -o -name 'interfaces.ts' 2>/dev/null)
  while IFS= read -r file; do
    if grep -qn '^export type\|^export interface' "$file" 2>/dev/null; then
      print_error "$file: move type exports to their module"
      found=1
    fi
  done < <(find src -name 'index.ts' 2>/dev/null)
  return $found
}
