#!/usr/bin/env bash
# Detect patterns that bypass TypeScript's safety guarantees.
#
# - eval(): code injection, breaks CSP, not optimisable by V8
# - as: lies to compiler, runtime crash if wrong
# - @ts-ignore: masks errors that resurface as bugs later
check_dangerous_patterns() {
# @see docs/adr/001-010/004-editorconfig-biome.md
  local found=0
  # eval() — security and performance hazard
  if bash scripts/lib/search.sh 'eval(' src/ | grep -qv "//.*eval"; then
    print_error "eval() found — security risk, restructure logic"
    found=1
  fi
  # Type assertions bypass the compiler (exclude import aliases)
  if bash scripts/lib/search.sh ' as [A-Z]' src/ | grep -v "import.*as\|//" | grep -q .; then
    print_error "'as' assertion found — use type guards or fix the type"
    found=1
  fi
  # Suppressed errors come back as bugs
  if bash scripts/lib/search.sh '@ts-ignore|@ts-expect-error' src/ | grep -q .; then
    print_error "@ts-ignore found — fix the type error instead"
    found=1
  fi
  return $found
}
