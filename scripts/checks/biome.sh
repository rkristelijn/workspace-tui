#!/usr/bin/env bash
# Auto-format and lint with Biome (applies safe fixes).
# @see docs/adr/004-editorconfig-biome.md
# Runs before other checks so formatting issues don't cascade.
check_biome() {
  pnpm exec biome check --write . > /dev/null 2>&1
}
