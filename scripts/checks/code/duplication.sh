#!/usr/bin/env bash
# Detect code duplication using jscpd.
# @see docs/adr/001-010/010-filesize-complexity-limits.md

check_duplication() {
  source scripts/lib/skip.sh
  should_skip "duplication" && return 0

  command -v npx > /dev/null 2>&1 || return 0

  local output
  output=$(npx jscpd src --min-lines 5 --min-tokens 50 --silent 2>&1 || true)
  local duplication
  duplication=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+%' | head -1 | tr -d '%' || echo "0")
  [[ -z "$duplication" ]] && duplication="0"

  local max="6"
  local int_dup="${duplication%%.*}"
  if [[ "$int_dup" -gt "$max" ]]; then
    print_error "Code duplication: ${duplication}% (max: ${max}%)"
    return 1
  fi
}
