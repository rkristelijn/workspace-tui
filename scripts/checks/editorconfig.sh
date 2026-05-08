#!/usr/bin/env bash
set -euo pipefail

# Check for trailing whitespace in source files
FOUND=0

while IFS= read -r file; do
  if grep -qn '[[:space:]]$' "$file" 2>/dev/null; then
    echo "$file: trailing whitespace"
    FOUND=1
  fi
done < <(find src scripts -name '*.ts' -o -name '*.sh' 2>/dev/null)

exit $FOUND
