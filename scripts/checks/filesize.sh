#!/usr/bin/env bash
set -euo pipefail

MAX_SOURCE=300
MAX_TEST=500
MAX_SCRIPT=200
FOUND=0

while IFS= read -r file; do
  lines=$(wc -l <"$file")
  [[ "$file" == *.test.ts || "$file" == *.spec.ts ]] && max=$MAX_TEST || max=$MAX_SOURCE
  if ((lines > max)); then
    echo "$file: $lines lines (max $max)"
    FOUND=1
  fi
done < <(find src -name '*.ts' 2>/dev/null)

while IFS= read -r file; do
  lines=$(wc -l <"$file")
  if ((lines > MAX_SCRIPT)); then
    echo "$file: $lines lines (max $MAX_SCRIPT)"
    FOUND=1
  fi
done < <(find scripts -name '*.sh' 2>/dev/null)

exit $FOUND
