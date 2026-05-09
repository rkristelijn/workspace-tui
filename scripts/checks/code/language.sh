#!/usr/bin/env bash
# Enforce English + active voice in code and docs.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_language() {
  source scripts/lib/skip.sh
  should_skip "language" && return 0

  local found=0
  if [[ -f ".config/dutch-words.txt" ]]; then
    while IFS= read -r word; do
      [[ "$word" =~ ^#.*$ ]] && continue
      [[ -z "$word" ]] && continue
      if bash scripts/lib/search.sh "\\b${word}\\b" | grep -v "language\|009-english" | grep -q .; then
        print_error "Dutch word found: ${word}"
        found=1
      fi
    done < ".config/dutch-words.txt"
  fi
  if [[ -f ".config/passive-voice.txt" ]]; then
    while IFS= read -r pattern; do
      [[ "$pattern" =~ ^#.*$ ]] && continue
      [[ -z "$pattern" ]] && continue
      if bash scripts/lib/search.sh "${pattern}" docs/adr/ | grep -v "language\|009-english" | grep -q .; then
        print_warning "Passive voice in ADR: '${pattern}'"
        found=1
      fi
    done < ".config/passive-voice.txt"
  fi
  return $found
}
