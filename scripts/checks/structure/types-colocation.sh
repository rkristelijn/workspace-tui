#!/usr/bin/env bash
# Types belong with their module, not in separate types.ts files.
# Why: Colocation keeps types close to their implementation.
# A types.ts file becomes a junk drawer that breaks module boundaries.
#
# @see docs/adr/001-010/003-interface-segregation.md
# Rules:
# - No files named types.ts or interfaces.ts (use the module file)
# - No type/interface exports from index.ts (index is orchestration)
check_types_colocation() {
  local found=0
  # No dedicated type files — types belong in their module
  while IFS= read -r file; do
    print_error "$file: colocate types in their module file"
    found=1
  done < <(find src -name 'types.ts' -o -name 'interfaces.ts' 2>/dev/null)
  # index.ts should not export types (it's the entry point, not a type source)
  while IFS= read -r file; do
    if grep -qn '^export type\|^export interface' "$file" 2>/dev/null; then
      print_error "$file: move type exports to their module"
      found=1
    fi
  done < <(find src -name 'index.ts' 2>/dev/null)
  return $found
}
