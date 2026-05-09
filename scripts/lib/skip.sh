#!/usr/bin/env bash
# Centralized skip logic — reads from checks-registry.json (single source of truth)
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

REGISTRY=".config/checks-registry.json"

# Check if a specific check should be skipped
# Usage: should_skip "check-name"
# Returns: 0 if should skip, 1 if should run
should_skip() {
  local check_name="$1"
  [[ ! -f "$REGISTRY" ]] && return 1

  local skip_enabled
  skip_enabled=$(jq -r ".checks[\"${check_name}\"].skip.enabled // false" "$REGISTRY" 2>/dev/null)

  if [[ "$skip_enabled" == "true" ]]; then
    local reason
    reason=$(jq -r ".checks[\"${check_name}\"].skip.reason // \"No reason\"" "$REGISTRY" 2>/dev/null)
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
  [[ ! -f "$REGISTRY" ]] && return 1

  local skip_enabled
  skip_enabled=$(jq -r ".checks[\"${check_name}\"].skip.enabled // false" "$REGISTRY" 2>/dev/null)
  [[ "$skip_enabled" != "true" ]] && return 1

  jq -e ".checks[\"${check_name}\"].skip.files // [] | index(\"${file_path}\")" "$REGISTRY" >/dev/null 2>&1
}
