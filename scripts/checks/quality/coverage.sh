#!/usr/bin/env bash
# Check script coverage — verify all checks are integrated
# @see docs/adr/011-020/014-git-workflow-quality-gates.md

check_script_coverage() {
  source scripts/lib/skip.sh
  should_skip "coverage" && return 0

  local found=0

  source scripts/lib/table.sh

  # Read integration points
  local precommit; precommit=$(grep "^CHECKS=" scripts/git/pre-commit.sh | sed 's/.*(\(.*\)).*/\1/' | tr ' ' '\n')
  local prepush; prepush=$(grep "^CHECKS=" scripts/git/pre-push.sh | sed 's/.*(\(.*\)).*/\1/' | tr ' ' '\n')
  local makefile; makefile=$(grep -E "^\s+@.*scripts/checks" Makefile 2>/dev/null || echo "")
  local package; package=$(grep -E "scripts/checks" package.json 2>/dev/null || echo "")

  printf "\n"
  print_table_header

  # Load skip config
  local skip_config=".config/checks-skip.json"
  local skip_data=""
  if [[ -f "$skip_config" ]]; then
    skip_data=$(cat "$skip_config")
  fi

  # Process by directory (grouped)
  local prev_dir=""
  while IFS= read -r file; do
    local dir; dir=$(dirname "$file" | sed 's|scripts/checks/||')
    local name; name=$(basename "$file" .sh)

    # Print directory header if changed
    if [[ "$dir" != "$prev_dir" ]]; then
      [[ -n "$prev_dir" ]] && printf "\n"
      echo -e "${BOLD}${dir}/${RESET}"
      prev_dir="$dir"
    fi

    # Check integration
    local pc="~" pp="~" mk="~" pkg="~"

    if echo "$precommit" | grep -q "^${name}$"; then
      pc="${GREEN}${CHECK}${RESET}"
    else
      pc="${RED}${CROSS}${RESET}"
      found=1
    fi

    if echo "$prepush" | grep -q "^${name}$"; then
      pp="${GREEN}${CHECK}${RESET}"
    else
      pp="${RED}${CROSS}${RESET}"
      found=1
    fi

    if [[ -n "$makefile" ]] && echo "$makefile" | grep -q "$name"; then
      mk="${GREEN}${CHECK}${RESET}"
    fi

    if [[ -n "$package" ]] && echo "$package" | grep -q "$name"; then
      pkg="${GREEN}${CHECK}${RESET}"
    fi

    # Check if skipped
    local skip_status=""
    if [[ -n "$skip_data" ]]; then
      local is_skipped; is_skipped=$(echo "$skip_data" | jq -r ".skip.${name}.enabled // false" 2>/dev/null)
      if [[ "$is_skipped" == "true" ]]; then
        skip_status=" ${YELLOW}(SKIP)${RESET}"
      fi
    fi

    print_table_row "  $name$skip_status" "$pc" "$pp" "$mk" "$pkg"
  done < <(find scripts/checks -name "*.sh" -type f | sort)

  printf "\n"
  [[ $found -eq 0 ]] && echo "✓ All checks integrated" || print_error "Some checks not integrated"

  return $found
}
