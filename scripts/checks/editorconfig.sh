#!/usr/bin/env bash
# Enforce .editorconfig rules that formatters might miss.
# @see docs/adr/006-editorconfig-biome.md
# Currently: trailing whitespace (causes noisy diffs).
check_editorconfig() {
  local found=0
  while IFS= read -r file; do
    if grep -qn '[[:space:]]$' "$file" 2>/dev/null; then
      print_error "$file: trailing whitespace"
      found=1
    fi
  done < <(find src scripts -name '*.ts' -o -name '*.sh' 2>/dev/null)
  return $found
}
