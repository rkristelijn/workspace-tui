#!/usr/bin/env bash
# UI utilities for consistent terminal output

# Detect terminal background (dark/light)
# Returns: "dark" or "light"
detect_theme() {
  # Check COLORFGBG env var (set by some terminals)
  # Format: "foreground;background" where 0-7 is dark, 8-15 is light
  if [[ -n "${COLORFGBG:-}" ]]; then
    local bg="${COLORFGBG##*;}"
    if [[ "$bg" =~ ^[0-7]$ ]]; then
      echo "dark"
      return
    elif [[ "$bg" =~ ^[89]$|^1[0-5]$ ]]; then
      echo "light"
      return
    fi
  fi
  
  # Default to dark (most common)
  echo "dark"
}

THEME="${THEME:-$(detect_theme)}"

# Colors for dark theme (high contrast on dark background)
if [[ "$THEME" == "dark" ]]; then
  RED='\033[0;91m'      # Bright red
  GREEN='\033[0;92m'    # Bright green
  YELLOW='\033[0;93m'   # Bright yellow
  BLUE='\033[0;94m'     # Bright blue
  GRAY='\033[0;90m'     # Dark gray
  RESET='\033[0m'
else
  # Colors for light theme (high contrast on light background)
  RED='\033[0;31m'      # Dark red
  GREEN='\033[0;32m'    # Dark green
  YELLOW='\033[0;33m'   # Dark yellow (brown)
  BLUE='\033[0;34m'     # Dark blue
  GRAY='\033[0;90m'     # Dark gray
  RESET='\033[0m'
fi

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
  echo -e "${GREEN}All checks passed${RESET} in ${GRAY}$1${RESET}"
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
