#!/usr/bin/env bash
set -euo pipefail

PII_FILE=".config/.pii"
[[ ! -f "$PII_FILE" ]] && exit 0

PATTERNS=()
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ ]] && continue
  [[ -z "$line" ]] && continue
  PATTERNS+=("$line")
done <"$PII_FILE"

[[ ${#PATTERNS[@]} -eq 0 ]] && exit 0

FOUND=0
for pattern in "${PATTERNS[@]}"; do
  if bash scripts/lib/search.sh "$pattern" | grep -qv "checks/pii.sh"; then
    echo "Found PII pattern: $pattern"
    FOUND=1
  fi
done

exit $FOUND
