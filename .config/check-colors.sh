#!/usr/bin/env bash
# Check for hardcoded ANSI color codes outside ui.sh
# All colors must go through ui.sh theme system

set -euo pipefail

FOUND=0
VIOLATIONS=()

# Check for ANSI escape codes in scripts (except ui.sh)
while IFS= read -r file; do
  [[ "$file" == *"ui.sh" ]] && continue
  
  if grep -n '\\033\[' "$file" 2>/dev/null; then
    VIOLATIONS+=("$file: hardcoded ANSI color code")
    FOUND=1
  fi
done < <(find .config -name '*.sh')

# Check for ANSI codes in TypeScript
while IFS= read -r file; do
  if grep -n '\\x1b\[' "$file" 2>/dev/null; then
    VIOLATIONS+=("$file: hardcoded ANSI color code")
    FOUND=1
  fi
done < <(find src -name '*.ts' -o -name '*.js')

if [[ $FOUND -eq 1 ]]; then
  for violation in "${VIOLATIONS[@]}"; do
    echo "$violation" >&2
    echo "  Use ui.sh functions instead" >&2
  done
  exit 1
fi
