#!/usr/bin/env bash
set -euo pipefail

# Pre-push runner — integrity checks before sharing code
# Runs all pre-commit checks + additional security/integrity checks
# @see docs/adr/014-git-workflow-quality-gates.md

source scripts/lib/ui.sh
source .config/checks.conf
for f in scripts/checks/*/*.sh; do source "$f"; done

# Pre-push: all pre-commit checks + additional integrity checks
CHECKS=(biome typescript filesize complexity docs comments colors search gitleaks pii language emoji async editorconfig dangerous-patterns filenames deps types-colocation clean-root no-hardcoded-secrets interface-segregation traceability coverage)
TOTAL=${#CHECKS[@]}
START_TIME=$(date +%s)

print_header "Pre-push integrity checks"

for i in "${!CHECKS[@]}"; do
  check="${CHECKS[$i]}"
  num="$(printf "%02d/%02d" $((i+1)) "$TOTAL")"
  STEP_START=$(date +%s)

  OUTPUT=$("check_${check//-/_}" 2>&1) && STATUS=0 || STATUS=$?
  STEP_END=$(date +%s)

  if [[ "$STATUS" -eq 0 ]]; then
    if [[ "$OUTPUT" == SKIP:* ]]; then
      print_step "$num" "$check" "skip" "${OUTPUT#SKIP: }"
    else
      print_step "$num" "$check" "success" "$((STEP_END - STEP_START))s"
    fi
  else
    print_step "$num" "$check" "error"
    [[ -n "$OUTPUT" ]] && printf "    %s\n" "$OUTPUT"
    printf "\n"
    print_error "Pre-push failed at: ${check}"
    exit 1
  fi
done

print_summary "$(($(date +%s) - START_TIME))s"
