#!/usr/bin/env bash
# UI utilities for consistent terminal output

# Get terminal dimensions
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)

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

# Wrap text to terminal width with indent
# Usage: wrap_text "long text..." 2
wrap_text() {
  local text="$1"
  local indent="${2:-0}"
  local width=$((TERM_WIDTH - indent))
  local spaces=$(printf "%${indent}s" "")
  
  echo "$text" | fold -s -w "$width" | while IFS= read -r line; do
    echo "${spaces}${line}"
  done
}

# Print step with timing
# Usage: print_step "1/5" "biome" "success" "2s"
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
# Usage: print_error "Branch name invalid" [indent]
print_error() {
  local msg="$1"
  local indent="${2:-0}"
  local spaces=$(printf "%${indent}s" "")
  echo -e "${spaces}${RED}ERROR:${RESET} ${msg}"
}

# Print warning message
# Usage: print_warning "Passive voice detected" [indent]
print_warning() {
  local msg="$1"
  local indent="${2:-0}"
  local spaces=$(printf "%${indent}s" "")
  echo -e "${spaces}${YELLOW}WARNING:${RESET} ${msg}"
}

# Print info message with wrapping
# Usage: print_info "Fix: use async/await" [indent]
print_info() {
  local msg="$1"
  local indent="${2:-0}"
  wrap_text "$msg" "$indent"
}

# Print line
# Usage: print_line "Testing..." [indent]
print_line() {
  local msg="$1"
  local indent="${2:-0}"
  local spaces=$(printf "%${indent}s" "")
  echo "${spaces}${msg}"
}

# Print summary
# Usage: print_summary "5s"
print_summary() {
  echo ""
  echo -e "${GREEN}All checks passed${RESET} in ${GRAY}$1${RESET}"
}
