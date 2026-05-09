#!/usr/bin/env bash
# Check script coverage — verify all checks are integrated
# @see docs/adr/011-020/014-git-workflow-quality-gates.md

check_script_coverage() {
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
      printf "\033[1m%s/\033[0m\n" "$dir"
      prev_dir="$dir"
    fi
    
    # Check integration
    local pc="~" pp="~" mk="~" pkg="~"
    
    if echo "$precommit" | grep -q "^${name}$"; then
      pc="\033[0;92m✓\033[0m"
    else
      pc="\033[0;91m✗\033[0m"
      found=1
    fi
    
    if echo "$prepush" | grep -q "^${name}$"; then
      pp="\033[0;92m✓\033[0m"
    else
      pp="\033[0;91m✗\033[0m"
      found=1
    fi
    
    if [[ -n "$makefile" ]] && echo "$makefile" | grep -q "$name"; then
      mk="\033[0;92m✓\033[0m"
    fi
    
    if [[ -n "$package" ]] && echo "$package" | grep -q "$name"; then
      pkg="\033[0;92m✓\033[0m"
    fi
    
    # Check if skipped
    local skip_status=""
    if [[ -n "$skip_data" ]]; then
      local is_skipped; is_skipped=$(echo "$skip_data" | jq -r ".skip.${name}.enabled // false" 2>/dev/null)
      if [[ "$is_skipped" == "true" ]]; then
        skip_status=" \033[0;93m(SKIP)\033[0m"
      fi
    fi
    
    print_table_row "  $name$skip_status" "$pc" "$pp" "$mk" "$pkg"
  done < <(find scripts/checks -name "*.sh" -type f | sort)
  
  printf "\n"
  [[ $found -eq 0 ]] && echo "✓ All checks integrated" || print_error "Some checks not integrated"
  
  return $found
}
