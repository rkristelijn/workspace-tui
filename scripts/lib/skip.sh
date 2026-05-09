#!/usr/bin/env bash
# Centralized skip logic for quality checks
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

# Check if a specific check should be skipped
# Usage: should_skip "check-name"
# Returns: 0 if should skip, 1 if should run
should_skip() {
  local check_name="$1"
  local skip_config=".config/checks-skip.json"
  
  [[ ! -f "$skip_config" ]] && return 1
  
  local skip_enabled; skip_enabled=$(jq -r ".skip.${check_name}.enabled // false" "$skip_config" 2>/dev/null)
  
  if [[ "$skip_enabled" == "true" ]]; then
    local reason; reason=$(jq -r ".skip.${check_name}.reason // \"No reason\"" "$skip_config" 2>/dev/null)
    echo "SKIP: $reason"
    return 0
  fi
  
  return 1
}

# Check if a specific file should be skipped for a check
# Usage: should_skip_file "check-name" "file-path"
# Returns: 0 if should skip, 1 if should check
should_skip_file() {
  local check_name="$1"
  local file_path="$2"
  local skip_config=".config/checks-skip.json"
  
  [[ ! -f "$skip_config" ]] && return 1
  
  local skip_enabled; skip_enabled=$(jq -r ".skip.${check_name}.enabled // false" "$skip_config" 2>/dev/null)
  [[ "$skip_enabled" != "true" ]] && return 1
  
  # Check if file is in skip list
  local skip_files; skip_files=$(jq -r ".skip.${check_name}.files[]?" "$skip_config" 2>/dev/null)
  
  while IFS= read -r skip_file; do
    [[ "$file_path" == "$skip_file" ]] && return 0
  done <<< "$skip_files"
  
  return 1
}
