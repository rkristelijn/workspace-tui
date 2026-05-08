#!/usr/bin/env bash
set -euo pipefail

SEARCH=".config/search.sh"
DUTCH_WORDS=".config/dutch-words.txt"
PASSIVE_VOICE=".config/passive-voice.txt"
FOUND=0

# Dutch words check
if [[ -f "$DUTCH_WORDS" ]]; then
  while IFS= read -r word; do
    [[ "$word" =~ ^#.*$ ]] && continue
    [[ -z "$word" ]] && continue
    
    if bash "$SEARCH" "\\b${word}\\b" | grep -v "check-language.sh"; then
      print_error " Found Dutch word: ${word}"
      FOUND=1
    fi
  done < "$DUTCH_WORDS"
fi

# Passive voice check (ADRs only)
if [[ -f "$PASSIVE_VOICE" ]]; then
  while IFS= read -r pattern; do
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue
    
    if bash "$SEARCH" "${pattern}" docs/adr/ | grep -v "check-language.sh"; then
      print_warning " Passive voice in ADR: '${pattern}'"
      printf "%s\n" "  Use active/declarative: 'Use X' instead of 'X is used'"
      FOUND=1
    fi
  done < "$PASSIVE_VOICE"
fi

if [[ $FOUND -eq 1 ]]; then
  exit 1
fi
