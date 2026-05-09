#!/usr/bin/env bash
set -euo pipefail

# Registry-driven pre-commit hook.
# Phase 1: Autofix (format staged files, re-stage)
# Phase 2: Check (fail-fast, only pre-commit tier from registry)
#
# @see docs/adr/011-020/022-safe-autofix-and-lib-enforcement.md
# @see docs/adr/011-020/020-shift-left-fail-fast-checks.md

source scripts/lib/ui.sh
source .config/checks.conf
for f in scripts/checks/*/*.sh; do source "$f"; done

REGISTRY=".config/checks-registry.json"

# ── Branch guard ──
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
[[ "$branch" == "main" ]] && { print_error "no direct commits to main"; exit 1; }
BRANCH_PATTERN="^(feat|fix|chore|docs|refactor|test|ci|style|perf|build)/[a-z0-9]+(-[a-z0-9]+)*$"
if [[ -n "$branch" ]] && ! [[ "$branch" =~ $BRANCH_PATTERN ]]; then
  print_error "branch '$branch' invalid — expected: type/description"
  exit 1
fi

# ── Detect staged files ──
STAGED=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
[[ -z "$STAGED" ]] && exit 0

HAS_TS=$(echo "$STAGED" | grep -c '\.ts$' || true)

# ── Phase 1: AUTOFIX (silent, re-stage) ──
if [[ "$HAS_TS" -gt 0 ]]; then
  TS_FILES=$(echo "$STAGED" | grep '\.ts$' || true)
  npx biome check --write $TS_FILES 2>/dev/null || true
  echo "$TS_FILES" | xargs git add 2>/dev/null || true
fi
# Editorconfig: trim trailing whitespace on staged files
echo "$STAGED" | while IFS= read -r f; do
  [[ -f "$f" ]] && grep -q '[[:space:]]$' "$f" 2>/dev/null && {
    sed 's/[[:space:]]*$//' "$f" > "$f.tmp" && mv "$f.tmp" "$f" && git add "$f"
  }
done

# ── Phase 2: CHECK (fail-fast, registry-driven) ──
CHECKS=$(jq -r '.checks | to_entries[] | select(.value.tier == "pre-commit") | select(.value.autofix == "none" or .value.autofix == "partial") | .key' "$REGISTRY")
TOTAL=$(echo "$CHECKS" | wc -l | tr -d ' ')
STEP=0
START_TIME=$(date +%s)

for check in $CHECKS; do
  STEP=$((STEP + 1))
  num="$(printf "%02d/%02d" "$STEP" "$TOTAL")"

  # Skip if configured in registry
  skipped=$(jq -r ".checks[\"$check\"].skip.enabled" "$REGISTRY")
  if [[ "$skipped" == "true" ]]; then
    reason=$(jq -r ".checks[\"$check\"].skip.reason" "$REGISTRY")
    print_step "$num" "$check" "skip" "$reason"
    continue
  fi

  # File-type filter: skip check if no relevant files staged
  filetypes=$(jq -r ".checks[\"$check\"].filetypes[]" "$REGISTRY" 2>/dev/null)
  if [[ "$filetypes" != "*" ]]; then
    relevant=0
    for ext in $filetypes; do
      echo "$STAGED" | grep -q "\.$ext$" && relevant=1 && break
    done
    [[ "$relevant" -eq 0 ]] && {
      print_step "$num" "$check" "skip" "no .$filetypes files"
      continue
    }
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
    print_error "pre-commit failed: $check"
    exit 1
  fi
done

print_summary "$(($(date +%s) - START_TIME))s"

# Log result for historical tracking
source scripts/lib/log.sh
log_run "pre-commit" 0
