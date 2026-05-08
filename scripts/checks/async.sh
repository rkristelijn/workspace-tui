#!/usr/bin/env bash
set -euo pipefail

FOUND=0

while IFS= read -r file; do
  if grep -qn "\.then(" "$file" 2>/dev/null; then
    echo "$file: use async/await instead of .then()"
    FOUND=1
  fi
  if grep -qn "new Promise(" "$file" 2>/dev/null; then
    if ! grep -q "createServer\|http\.\|on('data'" "$file"; then
      echo "$file: avoid new Promise() — use async functions"
      FOUND=1
    fi
  fi
  if grep -n "\.catch(" "$file" 2>/dev/null | grep -qv "main()\.catch"; then
    echo "$file: use try/catch instead of .catch()"
    FOUND=1
  fi
done < <(find src -name '*.ts' 2>/dev/null)

exit $FOUND
