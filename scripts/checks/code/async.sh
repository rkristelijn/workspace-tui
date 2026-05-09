#!/usr/bin/env bash
# Enforce async/await over raw Promises.
#
# Why: async/await gives better stack traces, readability, and type inference.
# Exceptions: new Promise() wrapping callback APIs (http.createServer),
# and top-level main().catch() as the standard Node entry point pattern.
check_async() {
# @see docs/adr/001-010/004-editorconfig-biome.md
  local found=0
  while IFS= read -r file; do
    if grep -qn "\.then(" "$file" 2>/dev/null; then
      print_error "$file: use async/await instead of .then()"
      found=1
    fi
    # Allow new Promise() only for callback-based APIs (http, streams)
    if grep -qn "new Promise(" "$file" 2>/dev/null; then
      if ! grep -q "createServer\|http\.\|on('data'" "$file"; then
        print_error "$file: avoid new Promise()"
        found=1
      fi
    fi
    # Allow main().catch() — standard top-level error boundary
    if grep -n "\.catch(" "$file" 2>/dev/null | grep -qv "main()\.catch"; then
      print_error "$file: use try/catch instead of .catch()"
      found=1
    fi
  done < <(find src -name '*.ts' 2>/dev/null)
  return $found
}
