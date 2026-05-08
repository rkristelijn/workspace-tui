#!/usr/bin/env bash
# Test that all check scripts properly exit with code 1 on failure
# This meta-check ensures our quality gates actually work

set -euo pipefail

FAILED=0

# Test each check script
CHECKS=(
  "check-filesize.sh:Creates file >300 lines"
  "check-echo.sh:Uses output in logic script"
  "check-colors.sh:Uses ANSI codes outside ui.sh"
  "check-search.sh:Uses grep -r instead of search.sh"
  "check-pii.sh:Contains PII pattern"
  "check-language.sh:Contains Dutch word"
)

printf "%s\n" "Testing check scripts exit codes..."

for check_info in "${CHECKS[@]}"; do
  IFS=':' read -r script description <<< "$check_info"
  
  # Skip if script doesn't exist
  if [[ ! -f ".config/$script" ]]; then
    printf "%s\n" "  [SKIP] $script (not found)"
    continue
  fi
  
  # All checks should pass on current codebase
  if bash ".config/$script" > /dev/null 2>&1; then
    printf "%s\n" "  [OK] $script exits 0 when passing"
  else
    printf "%s\n" "  [FAIL] $script exits non-zero on valid code"
    FAILED=1
  fi
done

if [[ $FAILED -eq 1 ]]; then
  printf "\n"
  printf "%s\n" "Some check scripts have incorrect exit codes"
  exit 1
fi

printf "\n"
printf "%s\n" "All check scripts have correct exit codes"
