#!/usr/bin/env bash
# Smart search utility - respects .gitignore
# Uses ripgrep (rg) if available, falls back to grep

set -euo pipefail

PATTERN="$1"
shift
PATHS="${@:-src/ docs/}"

# Use ripgrep if available (respects .gitignore by default)
if command -v rg > /dev/null 2>&1; then
  rg --no-heading --line-number "$PATTERN" $PATHS 2>/dev/null || true
else
  # Fallback to grep with manual .gitignore parsing
  EXCLUDES=""
  if [[ -f .gitignore ]]; then
    while IFS= read -r line; do
      # Skip comments and empty lines
      [[ "$line" =~ ^#.*$ ]] && continue
      [[ -z "$line" ]] && continue
      # Remove trailing slashes
      line="${line%/}"
      EXCLUDES="$EXCLUDES --exclude-dir=${line}"
    done < .gitignore
  fi
  
  grep -r --line-number $EXCLUDES "$PATTERN" $PATHS 2>/dev/null || true
fi
