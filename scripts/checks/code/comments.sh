#!/usr/bin/env bash
# Enforce minimum comment ratio across src/ and scripts/.
# Why: Comments explain *why*, not *what*. Undocumented code rots fast.
# Threshold from .config/checks.conf (MIN_COMMENT_RATIO).
# Skip config from .config/checks-skip.json
# Uses cloc for accurate language-aware counting.
# @see docs/adr/001-010/010-filesize-complexity-limits.md

check_comments() {
  # Check if skip is enabled
  local skip_config=".config/checks-skip.json"
  if [[ -f "$skip_config" ]]; then
    local skip_enabled; skip_enabled=$(jq -r '.skip.comments.enabled // false' "$skip_config" 2>/dev/null)
    if [[ "$skip_enabled" == "true" ]]; then
      local reason; reason=$(jq -r '.skip.comments.reason // "No reason"' "$skip_config" 2>/dev/null)
      echo "SKIP: $reason"
      return 0
    fi
  fi
  
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
