#!/usr/bin/env bash
set -euo pipefail

# Registry-driven pre-push hook.
# Runs ONLY pre-push tier checks (structural/architectural).
# Pre-commit tier already ran at commit time.
#
# @see docs/adr/011-020/020-shift-left-fail-fast-checks.md

source scripts/lib/ui.sh
source .config/checks.conf
for f in scripts/checks/*/*.sh; do source "$f"; done

REGISTRY=".config/checks-registry.json"

print_header "Pre-push integrity checks"

# Get checks assigned to pre-push tier
CHECKS=$(jq -r '.checks | to_entries[] | select(.value.tier == "pre-push") | .key' "$REGISTRY")
TOTAL=$(echo "$CHECKS" | wc -l | tr -d ' ')
STEP=0
START_TIME=$(date +%s)

for check in $CHECKS; do
  STEP=$((STEP + 1))
  num="$(printf "%02d/%02d" "$STEP" "$TOTAL")"

  # Skip if configured
  skipped=$(jq -r ".checks[\"$check\"].skip.enabled" "$REGISTRY")
  if [[ "$skipped" == "true" ]]; then
    reason=$(jq -r ".checks[\"$check\"].skip.reason" "$REGISTRY")
    print_step "$num" "$check" "skip" "$reason"
    continue
  fi

  # Run check
  STEP_START=$(date +%s)
  OUTPUT=$("check_${check//-/_}" 2>&1) && STATUS=0 || STATUS=$?
  elapsed="$(($(date +%s) - STEP_START))s"

  if [[ "$STATUS" -eq 0 ]]; then
    print_step "$num" "$check" "success" "$elapsed"
  else
    print_step "$num" "$check" "error"
    [[ -n "$OUTPUT" ]] && printf "    %s\n" "$OUTPUT"
    print_error "pre-push failed: $check"
    exit 1
  fi
done

print_summary "$(($(date +%s) - START_TIME))s"

# Log result for historical tracking
source scripts/lib/log.sh
log_run "pre-push" 0
