#!/usr/bin/env bash
# Bidirectional traceability: every decision has enforcement,
# every enforcement has a decision.
#
# - ADRs must have an ## Enforcement section
# - Check scripts must have a @see link to their ADR
#
# Exceptions: ADRs can use "N/A: design guideline" if not automatable.
# @see docs/adr/003-quality-driven-development.md
check_traceability() {
  local found=0

  # Every ADR must have ## Enforcement
  while IFS= read -r adr; do
    if ! grep -q "## Enforcement" "$adr" 2>/dev/null; then
      print_error "$adr: missing ## Enforcement section"
      found=1
    fi
  done < <(find docs/adr -name '*.md' 2>/dev/null)

  # Every check script must have @see linking to an ADR or design doc
  while IFS= read -r script; do
    if ! grep -q "@see" "$script" 2>/dev/null; then
      print_error "$script: missing @see link to ADR"
      found=1
    fi
  done < <(find scripts/checks -name '*.sh' 2>/dev/null)

  return $found
}
