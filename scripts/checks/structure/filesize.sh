#!/usr/bin/env bash
# Enforce max file size — large files signal SRP violations.
# Thresholds from .config/checks.conf
# Skip config from .config/checks-skip.json
# @see docs/adr/001-010/010-filesize-complexity-limits.md

check_filesize() {
  local found=0
  local skip_config=".config/checks-skip.json"
  local skip_enabled=false
  local skip_files=()
  
  # Load skip config if exists
  if [[ -f "$skip_config" ]]; then
    skip_enabled=$(jq -r '.skip.filesize.enabled // false' "$skip_config" 2>/dev/null)
    if [[ "$skip_enabled" == "true" ]]; then
      mapfile -t skip_files < <(jq -r '.skip.filesize.files[]?' "$skip_config" 2>/dev/null)
    fi
  fi
  
  while IFS= read -r file; do
    # Check if file is in skip list
    local should_skip=false
    for skip_file in "${skip_files[@]}"; do
      [[ "$file" == "$skip_file" ]] && should_skip=true && break
    done
    
    local lines; lines=$(wc -l <"$file")
    local max=$MAX_SOURCE_LINES
    [[ "$file" == *.test.ts || "$file" == *.spec.ts ]] && max=$MAX_TEST_LINES
    
    if ((lines > max)); then
      if [[ "$should_skip" == "true" ]]; then
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
