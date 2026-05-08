#!/usr/bin/env bash
# Check file sizes - keep files small and focused
# Limits: source 300, tests 500, scripts 200 lines

set -euo pipefail

source .config/ui.sh

MAX_SOURCE=300
MAX_TEST=500
MAX_SCRIPT=200

FOUND=0

while IFS= read -r file; do
  lines=$(wc -l <"$file")
  
  if [[ "$file" == *.test.ts || "$file" == *.spec.ts ]]; then
    max=$MAX_TEST
  else
    max=$MAX_SOURCE
  fi

  if ((lines > max)); then
    print_error "$file has $lines lines (max $max)"
    FOUND=1
  fi
done < <(find src -name '*.ts')

# Check shell scripts
while IFS= read -r file; do
  lines=$(wc -l <"$file")
  
  if ((lines > MAX_SCRIPT)); then
    print_error "$file has $lines lines (max $MAX_SCRIPT)"
    FOUND=1
  fi
done < <(find .config scripts -name '*.sh' 2>/dev/null)

if [[ $FOUND -eq 1 ]]; then
  exit 1
fi
