#!/usr/bin/env bash
set -euo pipefail

source scripts/lib/ui.sh

# Block commits to main
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [[ "${branch}" == "main" ]]; then
  print_error "direct commits to main not allowed"
  exit 1
fi

# Validate branch naming
PATTERN="^(feat|fix|chore|docs|refactor|test|ci|style|perf|build)/[a-z0-9]+(-[a-z0-9]+)*$"
if [[ -n "${branch}" ]] && ! [[ "${branch}" =~ ${PATTERN} ]]; then
  print_error "branch '${branch}' invalid — expected: type/description"
  exit 1
fi

# Checks to run (order matters)
CHECKS=(
  biome
  typescript
  filesize
  complexity
  comments
  colors
  search
  echo
  gitleaks
  pii
  language
  emoji
  async
  editorconfig
)

TOTAL=${#CHECKS[@]}
FAILED=0
START_TIME=$(date +%s)

for i in "${!CHECKS[@]}"; do
  check="${CHECKS[$i]}"
  num="$(printf "%02d/%02d" $((i+1)) "$TOTAL")"
  STEP_START=$(date +%s)

  OUTPUT=$(bash "scripts/checks/${check}.sh" 2>&1) && STATUS=0 || STATUS=$?
  STEP_END=$(date +%s)

  if [[ "$STATUS" -eq 0 ]]; then
    if echo "$OUTPUT" | grep -q "^SKIP:"; then
      print_step "$num" "$check" "skip" "${OUTPUT#SKIP: }"
    else
      print_step "$num" "$check" "success" "$((STEP_END - STEP_START))s"
    fi
  else
    print_step "$num" "$check" "error"
    [[ -n "$OUTPUT" ]] && printf "    %s\n" "$OUTPUT"
    FAILED=1
    break
  fi
done

END_TIME=$(date +%s)

if [[ $FAILED -eq 0 ]]; then
  print_summary "$((END_TIME - START_TIME))s"
else
  echo ""
  print_error "Pre-commit failed at check: ${CHECKS[$i]}"
  exit 1
fi
