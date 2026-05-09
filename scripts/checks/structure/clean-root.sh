#!/usr/bin/env bash
# Config files belong in .config/ — keep root clean.
# Allowed in root: package.json, biome.json, .editorconfig, .gitignore,
# .npmrc, .node-version, Makefile, README.md, pnpm-lock.yaml
# @see docs/adr/001-010/002-clean-root-config.md
ALLOWED_ROOT="package.json|biome.json|.editorconfig|.gitignore|.npmrc|.node-version|Makefile|README.md|pnpm-lock.yaml|.gitleaksignore"

check_clean_root() {
  local found=0
  while IFS= read -r file; do
    local base; base=$(basename "$file")
    if ! echo "$base" | grep -qE "^(${ALLOWED_ROOT})$"; then
      print_error "Unexpected config in root: $base — move to .config/"
      found=1
    fi
  done < <(find . -maxdepth 1 -name '*.json' -o -name '*.yaml' -o -name '*.yml' -o -name '*.toml' -o -name '*.conf' 2>/dev/null | grep -v "./package.json\|./biome.json\|./pnpm-lock.yaml")
  return $found
}
