#!/usr/bin/env bash
# Detect patterns that bypass TypeScript's safety guarantees.
# CMMI 1: eval() and @ts-ignore (always dangerous)
# @see docs/adr/011-020/021-cmmi-mapped-quality-matrix.md
check_dangerous_patterns() {
  local found=0
  if find src -name '*.ts' -exec grep -ln 'eval(' {} + 2>/dev/null | grep -qv '//.*eval'; then
    print_error "eval() found — security risk, restructure logic"
    found=1
  fi
  if find src -name '*.ts' -exec grep -ln '@ts-ignore\|@ts-expect-error' {} + 2>/dev/null | grep -q .; then
    print_error "@ts-ignore found — fix the type error instead"
    found=1
  fi
  return $found
}
