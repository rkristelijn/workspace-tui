#!/usr/bin/env bash
# Enforce async/await over raw Promises.
# Skip config from .config/checks-skip.json
# @see docs/adr/011-020/019-quality-check-skip-configuration.md

check_async() {
  source scripts/lib/skip.sh
  should_skip "async" && return 0

  local found=0
  while IFS= read -r file; do
    if grep -qn "\.then(" "$file" 2>/dev/null; then
      print_error "$file: use async/await instead of .then()"
      found=1
    fi
    if grep -qn "new Promise(" "$file" 2>/dev/null; then
      if ! grep -q "createServer\|http\.\|on('data'" "$file"; then
        print_error "$file: avoid new Promise()"
        found=1
      fi
    fi
    if grep -n "\.catch(" "$file" 2>/dev/null | grep -qv "main()\.catch"; then
      print_error "$file: use try/catch instead of .catch()"
      found=1
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  return $found
}
