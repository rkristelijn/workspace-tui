#!/usr/bin/env bash
# Check comment ratio - minimum 20% comments in source code

set -euo pipefail

THRESHOLD=20

# Check if cloc is installed
if ! command -v cloc > /dev/null 2>&1; then
  printf "%s\n" "cloc not installed (optional)" >&2
  exit 0
fi

# Get totals from cloc
totals=$(cloc src/ --exclude-dir=test --not-match-f='(\.test|\.spec)\.ts$' --csv --quiet 2>/dev/null | grep SUM || printf "\n")

if [[ -z "$totals" ]]; then
  exit 0
fi

comments=$(echo "$totals" | cut -d',' -f4)
code=$(echo "$totals" | cut -d',' -f5)
total=$((comments + code))

if [[ "$total" -eq 0 ]]; then
  exit 0
fi

ratio=$((comments * 100 / total))

if [[ "$ratio" -lt "$THRESHOLD" ]]; then
  printf "%s\n" "Comment ratio: ${ratio}% (minimum: ${THRESHOLD}%)" >&2
  printf "\n" >&2
  printf "%s\n" "Per-file breakdown:" >&2
  cloc src/ --exclude-dir=test --not-match-f='(\.test|\.spec)\.ts$' --by-file --csv --quiet 2>/dev/null |
    grep -v "^$\|^language\|SUM" |
    while IFS=',' read -r _ file _ fc fcode _; do
      ft=$((fc + fcode))
      if [[ "$ft" -gt 0 ]]; then
        fr=$((fc * 100 / ft))
        printf "  %3d%% %s\n" "$fr" "$file"
      fi
    done | sort -n | head -10 >&2
  exit 1
fi
