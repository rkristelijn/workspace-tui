#!/usr/bin/env bash
# Secret detection — prevents API keys, tokens, passwords in commits.
# Skips gracefully if gitleaks not installed (optional tool).
check_gitleaks() {
  if ! command -v gitleaks > /dev/null 2>&1; then
    echo "SKIP: not installed"
# @see docs/adr/008-config-file-credentials.md
    return 0
  fi
  gitleaks detect --no-git --redact > /dev/null 2>&1
}
