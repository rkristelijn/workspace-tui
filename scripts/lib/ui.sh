#!/usr/bin/env bash
# Shared UI library — single source of truth for terminal output.
#
# Why: Centralized color/formatting prevents hardcoded ANSI scattered
# across scripts. Respects NO_COLOR (https://no-color.org/) for
# accessibility and CI environments.
#
# Usage: source this file, then call print_* functions.
# Never use raw echo/printf for user-facing output in scripts.
#
# @see docs/adr/001-010/004-editorconfig-biome.md (consistency rules)

# Respect NO_COLOR standard for accessibility
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

# Step output for the pre-commit runner loop
print_step() {
  local num="$1" name="$2" status="$3" extra="${4:-}"
  printf "  [%s] %-22s " "$num" "$name"
  case "$status" in
    success) echo -e "${GREEN}${CHECK}${RESET} ${GRAY}${extra}${RESET}" ;;
    error)   echo -e "${RED}${CROSS}${RESET}" ;;
    skip)    echo -e "${GRAY}⊘ ${extra}${RESET}" ;;
  esac
}

print_error()   { echo -e "${RED}ERROR:${RESET} $1"; }
print_warning() { echo -e "${YELLOW}WARNING:${RESET} $1"; }
print_summary() { echo ""; echo -e "${GREEN}All checks passed${RESET} in ${GRAY}$1${RESET}"; }
print_header()  { echo ""; echo -e "${GREEN}$1${RESET}"; echo ""; }
