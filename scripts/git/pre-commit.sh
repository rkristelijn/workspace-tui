#!/usr/bin/env bash
set -euo pipefail

# Pre-commit runner — orchestrates quality checks as a single process.
#
# Architecture (barrel pattern):
#
#   pre-commit.sh (this file)
#       │
#       ├── source lib/ui.sh        → output formatting
#       ├── source checks.conf      → thresholds
#       └── source checks/*.sh      → each defines check_<name>()
#
# Each check is a pure function: returns 0 (pass) or 1 (fail),
# outputs error details via print_error/print_warning from ui.sh.
# No check runs standalone — this runner is the only entry point.
#
# @see docs/adr/001-010/003-quality-driven-development.md

source scripts/lib/ui.sh
source .config/checks.conf
for f in scripts/checks/*/*.sh; do source "$f"; done

# Branch guards — prevent accidental commits to main
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ "${branch}" == "main" ]]; then
  print_error "direct commits to main not allowed"
  exit 1
fi
BRANCH_PATTERN="^(feat|fix|chore|docs|refactor|test|ci|style|perf|build)/[a-z0-9]+(-[a-z0-9]+)*$"
if [[ -n "${branch}" ]] && ! [[ "${branch}" =~ ${BRANCH_PATTERN} ]]; then
  print_error "branch '${branch}' invalid — expected: type/description"
  exit 1
fi

# Ordered check list — fast checks first, slow checks last
CHECKS=(biome typescript filesize complexity docs comments colors search gitleaks pii language emoji async editorconfig dangerous-patterns filenames deps types-colocation clean-root no-hardcoded-secrets interface-segregation traceability)
TOTAL=${#CHECKS[@]}
START_TIME=$(date +%s)

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
    print_error "Pre-commit failed at: ${check}"
    exit 1
  fi
done

print_summary "$(($(date +%s) - START_TIME))s"
