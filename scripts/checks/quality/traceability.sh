#!/usr/bin/env bash
# Bidirectional traceability: every decision has enforcement,
# every enforcement has a decision.
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_traceability() {
  source scripts/lib/skip.sh
  should_skip "traceability" && return 0

  local found=0

  # ADRs (not READMEs) must have ## Enforcement
  while IFS= read -r adr; do
    [[ "$(basename "$adr")" == "README.md" ]] && continue
    if ! grep -q "## Enforcement" "$adr" 2>/dev/null; then
      print_error "$adr: missing ## Enforcement section"
      found=1
    fi
  done < <(find docs/adr -name '*.md' 2>/dev/null)

  # All check scripts must reference an ADR
  while IFS= read -r script; do
    if ! grep -q "@see" "$script" 2>/dev/null; then
      print_error "$script: missing @see link to ADR"
      found=1
    fi
  done < <(find scripts/checks -name '*.sh' 2>/dev/null)

  return $found
}
