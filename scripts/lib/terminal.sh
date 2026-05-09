#!/usr/bin/env bash
# Terminal size helpers

check_terminal_width() {
  local min_width=${1:-80}
  local cols; cols=$(tput cols 2>/dev/null || echo 80)

  if [[ $cols -lt $min_width ]]; then
    echo "⚠️  Terminal width: ${cols} cols (minimum ${min_width} recommended for tables)" >&2
    return 1
  fi
  return 0
}
