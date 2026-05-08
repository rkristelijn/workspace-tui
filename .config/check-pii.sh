#!/usr/bin/env bash
set -euo pipefail

PII_FILE=".config/.pii"
SEARCH=".config/search.sh"

if [[ ! -f "$PII_FILE" ]]; then
  exit 0
fi

PATTERNS=()
while IFS= read -r line; do
  [[ "$line" =~ ^#.*$ ]] && continue
  [[ -z "$line" ]] && continue
  PATTERNS+=("$line")
done <"$PII_FILE"

if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  exit 0
fi

FOUND=0
for pattern in "${PATTERNS[@]}"; do
  if bash "$SEARCH" "$pattern" | grep -v "check-pii.sh"; then
    echo "ERROR: Found PII pattern: $pattern"
    FOUND=1
  fi
done

if [[ $FOUND -eq 1 ]]; then
  echo "Remove sensitive data and use placeholders"
  exit 1
fi
