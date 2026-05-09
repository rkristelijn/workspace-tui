#!/usr/bin/env bash
# Enforce max file size — large files signal SRP violations.
# Thresholds from .config/checks.conf
# @see docs/adr/010-filesize-complexity-limits.md
check_filesize() {
  local found=0
  while IFS= read -r file; do
    local lines; lines=$(wc -l <"$file")
    local max=$MAX_SOURCE_LINES
    [[ "$file" == *.test.ts || "$file" == *.spec.ts ]] && max=$MAX_TEST_LINES
    ((lines > max)) && { print_error "$file: $lines lines (max $max)"; found=1; }
  done < <(find src -name '*.ts' 2>/dev/null)
  while IFS= read -r file; do
    local lines; lines=$(wc -l <"$file")
    ((lines > MAX_SCRIPT_LINES)) && { print_error "$file: $lines lines (max $MAX_SCRIPT_LINES)"; found=1; }
  done < <(find scripts -name '*.sh' 2>/dev/null)
  return $found
}
