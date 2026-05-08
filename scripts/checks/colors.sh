#!/usr/bin/env bash
# No hardcoded ANSI escape codes outside lib/ui.sh.
# Why: Centralized theming, NO_COLOR support, consistent output.
# @see scripts/lib/ui.sh
check_colors() {
  local found=0
  while IFS= read -r file; do
    [[ "$file" == *"lib/ui.sh" ]] && continue
    if grep -qn '\\033\[' "$file" 2>/dev/null; then
      print_error "$file: hardcoded ANSI — use scripts/lib/ui.sh"
      found=1
    fi
  done < <(find scripts -name '*.sh')
  while IFS= read -r file; do
    if grep -qn '\\x1b\[' "$file" 2>/dev/null; then
      print_error "$file: hardcoded ANSI"
      found=1
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  return $found
}
