#!/usr/bin/env bash
# Enforce kebab-case filenames for TypeScript.
# Why: macOS and Windows are case-insensitive — MyFile.ts and myfile.ts
# are the same file there but different on Linux CI → silent breakage.
# kebab-case avoids this entirely.
# @see docs/adr/001-010/004-editorconfig-biome.md
check_filenames() {
  local found=0
  while IFS= read -r file; do
    local base; base=$(basename "$file")
    # Allow: index.ts, single-word (base.ts), kebab-case (my-module.ts)
    if [[ "$base" =~ [A-Z] ]] || [[ "$base" =~ _ ]]; then
      print_error "$file: use kebab-case (e.g. my-module.ts)"
      found=1
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  return $found
}
