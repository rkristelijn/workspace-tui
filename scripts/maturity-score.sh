#!/usr/bin/env bash
set -euo pipefail
# Calculates CMMI maturity score from checks-registry.json
# @see docs/adr/011-020/021-cmmi-mapped-quality-matrix.md

REGISTRY=".config/checks-registry.json"
[[ -f "$REGISTRY" ]] || { echo "ERROR: $REGISTRY not found"; exit 1; }

# Weights per CMMI level
declare -A WEIGHTS=([0]=1 [1]=2 [2]=3 [3]=4)
declare -A LABELS=([0]="Initial" [1]="Managed" [2]="Defined" [3]="Optimizing")
declare -A TOTALS=([0]=0 [1]=0 [2]=0 [3]=0)
declare -A ACTIVE=([0]=0 [1]=0 [2]=0 [3]=0)
declare -A SKIPPED_NAMES=([0]="" [1]="" [2]="" [3]="")

while IFS= read -r line; do
  name=$(echo "$line" | jq -r '.name')
  cmmi=$(echo "$line" | jq -r '.cmmi')
  skipped=$(echo "$line" | jq -r '.skip.enabled')
  TOTALS[$cmmi]=$(( ${TOTALS[$cmmi]} + 1 ))
  if [[ "$skipped" != "true" ]]; then
    ACTIVE[$cmmi]=$(( ${ACTIVE[$cmmi]} + 1 ))
  else
    SKIPPED_NAMES[$cmmi]="${SKIPPED_NAMES[$cmmi]} $name"
  fi
done < <(jq -c '.checks | to_entries[] | {name: .key, cmmi: .value.cmmi, skip: .value.skip}' "$REGISTRY")

printf "\n  %-12s %-10s %-8s %-8s %s\n" "Level" "Active" "Score" "Max" "Skipped"
printf "  %-12s %-10s %-8s %-8s %s\n" "-----" "------" "-----" "---" "-------"

score=0; max=0
for level in 0 1 2 3; do
  w=${WEIGHTS[$level]}
  t=${TOTALS[$level]}
  a=${ACTIVE[$level]}
  level_score=$(( a * w ))
  level_max=$(( t * w ))
  score=$(( score + level_score ))
  max=$(( max + level_max ))
  skipped_list="${SKIPPED_NAMES[$level]}"
  [[ -z "$skipped_list" ]] && skipped_list="-"
  printf "  CMMI %-6s %d/%-8d %-8d %-8d %s\n" \
    "${level} (${LABELS[$level]})" "$a" "$t" "$level_score" "$level_max" "$skipped_list"
done

total_pct=$(( max > 0 ? (score * 100 / max) : 0 ))
printf "\n  Score: %d/%d (%d%%)\n" "$score" "$max" "$total_pct"

# Determine effective level (must have ALL checks active at lower levels)
if (( ${ACTIVE[0]} == ${TOTALS[0]} && ${ACTIVE[1]} == ${TOTALS[1]} && ${ACTIVE[2]} == ${TOTALS[2]} && ${ACTIVE[3]} == ${TOTALS[3]} )); then
  echo "  Level: CMMI 3 — Optimizing ★★★★"
elif (( ${ACTIVE[0]} == ${TOTALS[0]} && ${ACTIVE[1]} == ${TOTALS[1]} && ${ACTIVE[2]} == ${TOTALS[2]} )); then
  echo "  Level: CMMI 2 — Defined ★★★☆"
elif (( ${ACTIVE[0]} == ${TOTALS[0]} && ${ACTIVE[1]} == ${TOTALS[1]} )); then
  echo "  Level: CMMI 1 — Managed ★★☆☆"
elif (( ${ACTIVE[0]} == ${TOTALS[0]} )); then
  echo "  Level: CMMI 0+ — Initial (foundation complete) ★☆☆☆"
else
  echo "  Level: CMMI 0 — Initial ☆☆☆☆"
fi

# Warn about expired skips
printf "\n"
while IFS= read -r line; do
  name=$(echo "$line" | jq -r '.name')
  expires=$(echo "$line" | jq -r '.expires // empty')
  if [[ -n "$expires" ]] && [[ "$(date +%Y-%m-%d)" > "$expires" ]]; then
    printf "  ⚠ EXPIRED SKIP: %s (was due %s)\n" "$name" "$expires"
  fi
done < <(jq -c '.checks | to_entries[] | select(.value.skip.enabled == true) | {name: .key, expires: .value.skip.expires}' "$REGISTRY")
