#!/usr/bin/env bash
# Type-check without emitting — catches type errors before commit.
# @see docs/adr/004-editorconfig-biome.md
check_typescript() {
  pnpm exec tsc -p .config/tsconfig.json --noEmit 2>&1
}
