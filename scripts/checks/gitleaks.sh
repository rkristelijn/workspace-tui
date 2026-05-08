#!/usr/bin/env bash
set -euo pipefail

if ! command -v gitleaks > /dev/null 2>&1; then
  echo "SKIP: gitleaks not installed"
  exit 0
fi

gitleaks detect --no-git --redact > /dev/null 2>&1
