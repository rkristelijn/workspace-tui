#!/usr/bin/env bash
# Detect patterns that bypass TypeScript's safety guarantees.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_dangerous_patterns() {
  source scripts/lib/skip.sh
  should_skip "dangerous-patterns" && return 0

  local found=0
  if bash scripts/lib/search.sh 'eval(' src/ | grep -qv "//.*eval"; then
    print_error "eval() found — security risk, restructure logic"
    found=1
  fi
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
