#!/usr/bin/env bash
# Shared UI utilities for consistent terminal output

TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Colors (respects NO_COLOR)
if [[ -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;91m'
  GREEN='\033[0;92m'
  YELLOW='\033[0;93m'
  GRAY='\033[0;90m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' GRAY='' RESET=''
fi

CHECK="✓"
CROSS="✗"
SKIP="⊘"

print_step() {
  local num="$1" name="$2" status="$3" extra="${4:-}"
  printf "  [%s] %-12s " "$num" "$name"
  case "$status" in
    success) echo -e "${GREEN}${CHECK}${RESET} ${GRAY}(${extra})${RESET}" ;;
    error)   echo -e "${RED}${CROSS}${RESET}" ;;
    skip)    echo -e "${GRAY}${SKIP} (${extra})${RESET}" ;;
    fixed)   echo -e "${GREEN}${CHECK}${RESET} ${YELLOW}(${extra})${RESET}" ;;
  esac
}

print_section() { echo ""; echo "-- $1 --"; }
print_error() { echo -e "${RED}ERROR:${RESET} $1"; }
print_warning() { echo -e "${YELLOW}WARNING:${RESET} $1"; }
print_summary() { echo ""; echo -e "${GREEN}All checks passed${RESET} in ${GRAY}$1${RESET}"; }
