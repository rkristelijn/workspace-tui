#!/usr/bin/env bash
set -euo pipefail

source .config/ui.sh

for script in .config/check-*.sh .config/test-checks.sh; do
  [[ "$script" == ".config/check-echo.sh" ]] && continue
  
  tmp=$(mktemp)
  
  while IFS= read -r line; do
    if [[ "$line" =~ \$\(echo ]]; then
      printf "%s\n" "$line"
    elif [[ "$line" =~ echo[[:space:]]+\"ERROR: ]]; then
      printf "%s\n" "${line//echo \"ERROR:/print_error \"}"
    elif [[ "$line" =~ echo[[:space:]]+\"WARNING: ]]; then
      printf "%s\n" "${line//echo \"WARNING:/print_warning \"}"
    elif [[ "$line" =~ ^[[:space:]]*echo[[:space:]]+\"\"$ ]]; then
      printf "%s\n" "${line//echo \"\"/printf \"\\n\"}"
    elif [[ "$line" =~ ^[[:space:]]*echo[[:space:]] ]]; then
      printf "%s\n" "${line//echo /printf \"%s\\n\" }"
    else
      printf "%s\n" "$line"
    fi
  done < "$script" > "$tmp"
  
  mv "$tmp" "$script"
  chmod +x "$script"
done

print_info "Autofix complete"
