#!/usr/bin/env bash
# Secret detection — prevents API keys, tokens, passwords in commits.
# @see docs/adr/001-010/006-config-file-credentials.md

check_gitleaks() {
  if ! command -v gitleaks > /dev/null 2>&1; then
    echo "SKIP: not installed"
    return 0
  fi
  gitleaks detect --no-git --redact --config=.config/.gitleaks.toml > /dev/null 2>&1
}
