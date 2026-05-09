#!/usr/bin/env bash
# No hardcoded credentials, API keys, or URLs with tokens in source.
# Credentials come from config file or env vars, never committed.
# @see docs/adr/006-config-file-credentials.md
check_no_hardcoded_secrets() {
  local found=0
  # API keys, tokens, secrets as string literals
  if bash scripts/lib/search.sh '(api_key|apikey|secret|token|password)\s*[:=]\s*["\x27][^"\x27]{8,}' src/ | grep -qv "process\.env\|\.example\|config\."; then
    print_error "Possible hardcoded secret in src/ — use env vars or config"
    found=1
  fi
  # Hardcoded localhost URLs with ports (often contain dev tokens)
  if bash scripts/lib/search.sh 'https?://[^"]*\.(googleapis|google)\.com/.*key=' src/ | grep -q .; then
    print_error "URL with API key in src/ — use env var"
    found=1
  fi
  return $found
}
