#!/usr/bin/env bash
# Types belong with their module, not in separate types.ts files.
# Exception: src/data/types.ts is the shared domain model (by design).
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_types_colocation() {
  source scripts/lib/skip.sh
  should_skip "types-colocation" && return 0

  local found=0
  while IFS= read -r file; do
    # Allow shared domain types in data/
    [[ "$file" == *"data/types.ts" ]] && continue
    print_error "$file: colocate types in their module file"
    found=1
  done < <(find src -name 'types.ts' -o -name 'interfaces.ts' 2>/dev/null)

  while IFS= read -r file; do
    # Allow re-exports from index.ts (facade pattern)
    if grep -n '^export type\|^export interface' "$file" 2>/dev/null | grep -qv 'export type {'; then
      print_error "$file: define types in dedicated module, not index.ts"
      found=1
    fi
  done < <(find src -name 'index.ts' 2>/dev/null)

  return $found
}
