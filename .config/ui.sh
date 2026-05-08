#!/usr/bin/env bash
# UI utilities for consistent terminal output

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
RESET='\033[0m'

# Symbols
CHECK="✓"
CROSS="✗"
SKIP="⊘"

# Print step with timing
# Usage: print_step "1/5" "biome" "success" "2s"
# Usage: print_step "1/5" "biome" "error"
# Usage: print_step "1/5" "biome" "skip" "not installed"
print_step() {
  local num="$1"
  local name="$2"
  local status="$3"
  local extra="${4:-}"
  
  printf "  [%s] %-12s " "$num" "$name..."
  
  case "$status" in
    success)
      echo -e "${GREEN}${CHECK}${RESET} ${GRAY}(${extra})${RESET}"
      ;;
    error)
      echo -e "${RED}${CROSS}${RESET}"
      ;;
    skip)
      echo -e "${GRAY}${SKIP} (${extra})${RESET}"
      ;;
    fixed)
      echo -e "${GREEN}${CHECK}${RESET} ${YELLOW}(${extra})${RESET}"
      ;;
  esac
}

# Print section header
# Usage: print_section "Formatting"
print_section() {
  echo ""
  echo "-- $1 --"
}

# Print error message
# Usage: print_error "Branch name invalid"
print_error() {
  echo -e "${RED}ERROR:${RESET} $1"
}

# Print warning message
# Usage: print_warning "Passive voice detected"
print_warning() {
  echo -e "${YELLOW}WARNING:${RESET} $1"
}

# Print summary
# Usage: print_summary "5s"
print_summary() {
  echo ""
  echo -e "${GREEN}All checks passed${RESET} in ${BLUE}$1${RESET}"
}

# Run step with timing
# Usage: run_step "command to run"
# Returns: elapsed time in seconds
run_step() {
  local start=$(date +%s)
  eval "$1"
  local end=$(date +%s)
  echo $((end - start))
}
