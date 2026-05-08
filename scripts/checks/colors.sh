#!/usr/bin/env bash
set -euo pipefail

FOUND=0

# No hardcoded ANSI in scripts (except ui.sh)
while IFS= read -r file; do
  [[ "$file" == *"lib/ui.sh" ]] && continue
  if grep -qn '\\033\[' "$file" 2>/dev/null; then
    echo "$file: hardcoded ANSI — use scripts/lib/ui.sh"
    FOUND=1
  fi
done < <(find scripts -name '*.sh')

# No hardcoded ANSI in TypeScript
while IFS= read -r file; do
  if grep -qn '\\x1b\[' "$file" 2>/dev/null; then
    echo "$file: hardcoded ANSI"
    FOUND=1
  fi
done < <(find src -name '*.ts' 2>/dev/null)

exit $FOUND
