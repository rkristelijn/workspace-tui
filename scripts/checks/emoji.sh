#!/usr/bin/env bash
# No Unicode emoji in source — use ASCII or kaomoji instead.
# @see docs/adr/013-terminal-theme-accessibility.md
# Why: Emoji render inconsistently across terminals and fonts.
check_emoji() {
  local hits; hits=$(bash scripts/lib/search.sh '[\x{1F300}-\x{1F9FF}]' 2>/dev/null | grep -v "checks/emoji" || true)
  if [[ -n "$hits" ]]; then
    print_error "Emoji found in source"
    return 1
  fi
}
