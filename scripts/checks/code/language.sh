#!/usr/bin/env bash
# Enforce English + active voice in code and docs.
# @see docs/adr/001-010/007-english-active-voice.md

check_language() {
  source scripts/lib/skip.sh
  should_skip "language" && return 0
  source scripts/lib/search.sh

  local found=0
  if [[ -f ".config/dutch-words.txt" ]]; then
    while IFS= read -r word; do
      [[ "$word" =~ ^#.*$ || -z "$word" ]] && continue
      if search_files "\\b${word}\\b" src/ docs/ | grep -v "dutch-words\|language\|007-english" | grep -q .; then
        print_error "Dutch word found: ${word}"
        found=1
      fi
    done < ".config/dutch-words.txt"
  fi
  return $found
}
