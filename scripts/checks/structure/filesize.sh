#!/usr/bin/env bash
# Enforce max file size — large files signal SRP violations.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_filesize() {
  source scripts/lib/skip.sh
  
  local found=0
  while IFS= read -r file; do
    local lines; lines=$(wc -l <"$file")
    local max=$MAX_SOURCE_LINES
    [[ "$file" == *.test.ts || "$file" == *.spec.ts ]] && max=$MAX_TEST_LINES
    
    if ((lines > max)); then
      if should_skip_file "filesize" "$file"; then
        print_warning "$file: $lines lines (max $max) - SKIPPED"
      else
        print_error "$file: $lines lines (max $max)"
        found=1
      fi
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  
  while IFS= read -r file; do
    local lines; lines=$(wc -l <"$file")
    ((lines > MAX_SCRIPT_LINES)) && { print_error "$file: $lines lines (max $MAX_SCRIPT_LINES)"; found=1; }
  done < <(find scripts -name '*.sh' 2>/dev/null)
  
  return $found
}
