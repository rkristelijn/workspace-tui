#!/usr/bin/env bash
# Check file sizes - keep files small and focused
# Limits: source 300, tests 500 lines

set -euo pipefail

MAX_SOURCE=300
MAX_TEST=500

FOUND=0
VIOLATIONS=()

while IFS= read -r file; do
  lines=$(wc -l <"$file")
  
  # Determine limit based on file type
  if [[ "$file" == *.test.ts || "$file" == *.spec.ts ]]; then
    max=$MAX_TEST
  else
    max=$MAX_SOURCE
  fi

  if ((lines > max)); then
    VIOLATIONS+=("$file has $lines lines (max $max)")
    FOUND=1
  fi
done < <(find src -name '*.ts' -o -name '*.js')

# Output violations to stderr for caller to handle
if [[ $FOUND -eq 1 ]]; then
  for violation in "${VIOLATIONS[@]}"; do
    echo "$violation" >&2
  done
  exit 1
fi
