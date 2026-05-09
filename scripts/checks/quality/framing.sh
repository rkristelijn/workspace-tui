#!/usr/bin/env bash
# Check for negative IT framing — stay in power, not force.
# Why: Positive language keeps energy high and solutions-focused.
check_framing() {
  local found=0
  local -A reframe=(
    ["problem"]="challenge"
    ["issue"]="opportunity"
    ["blocker"]="dependency"
    ["blocked"]="waiting on"
    ["bug"]="unexpected behavior"
    ["broken"]="needs attention"
    ["failed"]="learned"
    ["failure"]="learning"
    ["error"]="signal"
    ["crash"]="restart needed"
    ["technical debt"]="refactoring opportunity"
    ["legacy code"]="existing system"
    ["hack"]="workaround"
    ["impossible"]="challenging"
    ["can't"]="exploring how to"
    ["stuck"]="investigating"
  )

  while IFS= read -r file; do
    for word in "${!reframe[@]}"; do
      if grep -qinw "$word" "$file" 2>/dev/null; then
        local lines=$(grep -inw "$word" "$file" | head -3)
        print_error "$file: '$word' → '${reframe[$word]}'"
        echo "$lines" | while read -r line; do
          echo "  $line"
        done
        found=1
      fi
    done
  done < <(find . -name '*.md' -o -name '*.ts' -o -name '*.sh' | grep -v node_modules | grep -v .git)

  return $found
}
