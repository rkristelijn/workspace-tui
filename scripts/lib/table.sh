#!/usr/bin/env bash
# Table formatting helper — handles ANSI codes in column width calculation

# Print table row with proper alignment (accounts for ANSI escape codes)
print_table_row() {
  local -a cols=("$@")
  local -a widths=(30 12 12 12 12)
  
  for i in "${!cols[@]}"; do
    local col="${cols[$i]}"
    local width="${widths[$i]}"
    
    # Calculate visible length (strip ANSI codes)
    local visible; visible=$(echo -e "$col" | sed 's/\x1b\[[0-9;]*m//g')
    local visible_len=${#visible}
    
    # Calculate padding needed
    local padding=$((width - visible_len))
    [[ $padding -lt 0 ]] && padding=0
    
    # Print column with padding
    printf "%b%*s" "$col" "$padding" ""
  done
  printf "\n"
}

# Print table separator
print_table_separator() {
  local total_width=78
  printf "%.s─" $(seq 1 "$total_width")
  printf "\n"
}

# Print table header
print_table_header() {
  print_table_row "Check" "Pre-commit" "Pre-push" "Makefile" "package.json"
  print_table_separator
}
