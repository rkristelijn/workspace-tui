#!/usr/bin/env bash
# Enforce English + active voice in code and docs.
# Why: Consistent language for international collaboration.
# Word lists in .config/dutch-words.txt and .config/passive-voice.txt
# @see docs/adr/007-english-active-voice.md (if exists)
check_language() {
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
