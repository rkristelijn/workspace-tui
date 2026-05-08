#!/usr/bin/env bash
# Flag trivial dependencies — libs you can write in <10 lines.
# Why: Each dep is supply chain attack surface + maintenance burden.
# @see https://en.wikipedia.org/wiki/Npm_left-pad_incident
TRIVIAL_DEPS=(
  is-even is-odd is-number is-positive-integer
  left-pad right-pad
  is-array is-string is-boolean
  noop identity
)

check_deps() {
  local found=0
  for dep in "${TRIVIAL_DEPS[@]}"; do
    if [[ -d "node_modules/$dep" ]]; then
      print_error "Trivial dep '$dep' — write it yourself"
      found=1
    fi
  done
  return $found
}
