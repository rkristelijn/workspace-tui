#!/usr/bin/env bash
# Cyclomatic/cognitive complexity — max 10 per function.
# Enforced via Biome's noExcessiveCognitiveComplexity rule.
# This check verifies the rule is active (biome check catches violations).
# @see docs/adr/010-filesize-complexity-limits.md
check_complexity() {
  # Biome handles this in check_biome — this validates the rule exists
  if ! grep -q "noExcessiveCognitiveComplexity" biome.json 2>/dev/null; then
    print_error "Complexity rule missing from biome.json"
    return 1
  fi
}
