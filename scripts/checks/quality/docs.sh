#!/usr/bin/env bash
# Validate docs structure — naming, numbering, max files per directory
# @see docs/process/workflow.md

check_docs() {
  local found=0
  
  # Check ADR numbering: sequential, no gaps, no duplicates
  local adr_dir="docs/adr"
  if [[ -d "$adr_dir" ]]; then
    local numbers=()
    while IFS= read -r file; do
      local num; num=$(basename "$file" | grep -oE '^[0-9]+')
      [[ -n "$num" ]] && numbers+=("$num")
    done < <(find "$adr_dir" -name '[0-9]*.md' | sort)
    
    # Check for duplicates
    local sorted; sorted=$(printf '%s\n' "${numbers[@]}" | sort -n)
    local unique; unique=$(printf '%s\n' "${numbers[@]}" | sort -nu)
    if [[ "$sorted" != "$unique" ]]; then
      print_error "ADR: Duplicate numbers found"
      found=1
    fi
    
    # Check sequential (starting from 001 or 002)
    local expected=1
    [[ "${numbers[0]}" == "002" ]] && expected=2
    for num in "${numbers[@]}"; do
      local n=$((10#$num))
      if ((n != expected)); then
        print_error "ADR: Expected $expected, found $num (gap or wrong order)"
        found=1
        break
      fi
      ((expected++))
    done
  fi
  
  # Check max files per directory (excluding subdirs, excluding decade folders)
  local max_files=10
  while IFS= read -r dir; do
    # Skip decade folders like 001-010, 011-020
    [[ "$(basename "$dir")" =~ ^[0-9]{3}-[0-9]{3}$ ]] && continue
    
    local count; count=$(find "$dir" -maxdepth 1 -type f | wc -l | tr -d ' ')
    if ((count > max_files)); then
      print_error "$dir: $count files (max $max_files)"
      found=1
    fi
  done < <(find docs -type d)
  
  # Check naming convention: NNN-kebab-case.md for numbered docs
  while IFS= read -r file; do
    local name; name=$(basename "$file")
    if [[ "$name" =~ ^[0-9] ]] && ! [[ "$name" =~ ^[0-9]{3}-[a-z0-9-]+\.md$ ]]; then
      print_error "$file: Invalid naming (use NNN-kebab-case.md)"
      found=1
    fi
  done < <(find docs -name '[0-9]*.md')
  
  return $found
}
