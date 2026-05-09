#!/usr/bin/env bash
# Detect PII (names, emails, hostnames) leaking into source.
# @see docs/adr/001-010/005-pii-detection.md
# Patterns defined in .config/.pii (gitignored, per-developer).
check_pii() {
  local pii_file=".config/.pii"
  [[ ! -f "$pii_file" ]] && return 0
  local patterns=()
  while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    patterns+=("$line")
  done <"$pii_file"
  [[ ${#patterns[@]} -eq 0 ]] && return 0
  local found=0
  for pattern in "${patterns[@]}"; do
    if bash scripts/lib/search.sh "$pattern" | grep -qv "\.pii"; then
      print_error "Found PII pattern: $pattern"
      found=1
    fi
  done
  return $found
}
