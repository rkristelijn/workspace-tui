#!/usr/bin/env bash
# Enforce minimum comment ratio across src/ and scripts/.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_comments() {
  source scripts/lib/skip.sh
  should_skip "comments" && return 0

  command -v cloc > /dev/null 2>&1 || return 0
  local totals; totals=$(cloc src/ scripts/ --not-match-f='(\.test|\.spec)\.ts$' --csv --quiet 2>/dev/null | grep SUM || true)
  [[ -z "$totals" ]] && return 0
  local comments; comments=$(echo "$totals" | cut -d',' -f4)
  local code; code=$(echo "$totals" | cut -d',' -f5)
  local total=$((comments + code))
  [[ "$total" -eq 0 ]] && return 0
  local ratio=$((comments * 100 / total))
  if [[ "$ratio" -lt "$MIN_COMMENT_RATIO" ]]; then
    print_error "Comment ratio: ${ratio}% (minimum: ${MIN_COMMENT_RATIO}%)"
    return 1
  fi
}
