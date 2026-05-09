#!/usr/bin/env bash
# Enforce .editorconfig rules: trailing whitespace.
# @see docs/adr/001-010/004-editorconfig-biome.md
check_editorconfig() {
  local found=0
  while IFS= read -r file; do
    if grep -qn '[[:space:]]$' "$file" 2>/dev/null; then
      if [[ "${FIX:-0}" == "1" ]]; then
        # Portable: tmp file + mv (no sed -i, see .config/denylist.md)
        sed 's/[[:space:]]*$//' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
      else
        print_error "$file: trailing whitespace"
        found=1
      fi
    fi
  done < <(find src scripts -name '*.ts' -o -name '*.sh' 2>/dev/null)
  return $found
}
