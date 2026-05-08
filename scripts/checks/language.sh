#!/usr/bin/env bash
set -euo pipefail

DUTCH_WORDS=".config/dutch-words.txt"
PASSIVE_VOICE=".config/passive-voice.txt"
FOUND=0

if [[ -f "$DUTCH_WORDS" ]]; then
  while IFS= read -r word; do
    [[ "$word" =~ ^#.*$ ]] && continue
    [[ -z "$word" ]] && continue
    if bash scripts/lib/search.sh "\\b${word}\\b" | grep -v "checks/language.sh\|009-english-active-voice" | grep -q .; then
      echo "Dutch word found: ${word}"
      FOUND=1
    fi
  done < "$DUTCH_WORDS"
fi

if [[ -f "$PASSIVE_VOICE" ]]; then
  while IFS= read -r pattern; do
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue
    if bash scripts/lib/search.sh "${pattern}" docs/adr/ | grep -v "checks/language.sh\|009-english-active-voice" | grep -q .; then
      echo "Passive voice in ADR: '${pattern}'"
      FOUND=1
    fi
  done < "$PASSIVE_VOICE"
fi

exit $FOUND
