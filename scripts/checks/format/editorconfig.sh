#!/usr/bin/env bash
# Enforce .editorconfig rules that formatters might miss.
# @see docs/adr/001-010/004-editorconfig-biome.md
# Currently: trailing whitespace (causes noisy diffs).
check_editorconfig() {
  local found=0
  while IFS= read -r file; do
    if grep -qn '[[:space:]]$' "$file" 2>/dev/null; then
      # Autofix if FIX=1
      if [[ "${FIX:-0}" == "1" ]]; then
        sed -i '' 's/[[:space:]]*$//' "$file"
      else
        print_error "$file: trailing whitespace"
        found=1
      fi
    fi
  done < <(find src scripts -name '*.ts' -o -name '*.sh' 2>/dev/null)
  return $found
}
