#!/usr/bin/env bash
set -euo pipefail

if ! command -v cloc > /dev/null 2>&1; then
  exit 0
fi

totals=$(cloc src/ --exclude-dir=test --not-match-f='(\.test|\.spec)\.ts$' --csv --quiet 2>/dev/null | grep SUM || true)
[[ -z "$totals" ]] && exit 0

comments=$(echo "$totals" | cut -d',' -f4)
code=$(echo "$totals" | cut -d',' -f5)
total=$((comments + code))
[[ "$total" -eq 0 ]] && exit 0

ratio=$((comments * 100 / total))
if [[ "$ratio" -lt 20 ]]; then
  echo "Comment ratio: ${ratio}% (minimum: 20%)"
  exit 1
fi
