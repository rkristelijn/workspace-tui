#!/usr/bin/env bash
# Check for negative IT framing — stay in power, not force.
# @see docs/adr/011-020/023-process-driven-maturity-model.md
# Warning-only: does not block until autofix is available.

check_framing() {
  local -A reframe=(
    ["problem"]="challenge"
    ["issue"]="opportunity"
    ["blocker"]="dependency"
    ["blocked"]="waiting on"
    ["bug"]="unexpected behavior"
    ["broken"]="needs attention"
    ["failed"]="learned"
    ["failure"]="learning"
    ["technical debt"]="refactoring opportunity"
    ["legacy code"]="existing system"
    ["hack"]="workaround"
    ["impossible"]="challenging"
    ["stuck"]="investigating"
  )

  # Only check docs and comments, not code logic
  local files
  files=$(find docs -name '*.md' 2>/dev/null; find . -maxdepth 1 -name '*.md' 2>/dev/null)

  for file in $files; do
    # Skip this check's own file and ADR examples
    [[ "$file" == *"framing"* ]] && continue
    [[ "$file" == *"denylist"* ]] && continue
    [[ "$file" == *"024-"* ]] && continue

    for word in "${!reframe[@]}"; do
      if grep -qinw "$word" "$file" 2>/dev/null; then
        print_warning "$file: '$word' → consider '${reframe[$word]}'"
      fi
    done
  done

  # Always pass — warnings only
  return 0
}
