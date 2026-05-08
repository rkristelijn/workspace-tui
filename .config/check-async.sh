#!/usr/bin/env bash
# Enforce async/await over promises
set -euo pipefail

source .config/ui.sh

FOUND=0

# Check for .then()
while IFS= read -r file; do
  if grep -n "\.then(" "$file" 2>/dev/null; then
    print_error "Use async/await in $file"
    print_info "Why: Better readability, type safety, and stack traces" 2
    print_info "Fix: await promise instead of promise.then()" 2
    FOUND=1
  fi
done < <(find src -name '*.ts')

# Check for new Promise
while IFS= read -r file; do
  if grep -n "new Promise(" "$file" 2>/dev/null; then
    print_error "Avoid new Promise() in $file"
    print_info "Why: Unnecessary wrapper, use async functions" 2
    print_info "Fix: Make function async and return value directly" 2
    FOUND=1
  fi
done < <(find src -name '*.ts')

# Check for .catch()
while IFS= read -r file; do
  if grep -n "\.catch(" "$file" 2>/dev/null; then
    print_error "Use try/catch in $file"
    print_info "Why: Consistent error handling with async/await" 2
    print_info "Fix: Wrap await in try/catch block" 2
    FOUND=1
  fi
done < <(find src -name '*.ts')

# Check for long method chains (>4)
while IFS= read -r file; do
  while IFS= read -r line; do
    dots=$(printf "%s" "$line" | grep -o '\.' | grep -v '?\.' | wc -l | tr -d ' ')
    if [[ $dots -gt 4 ]]; then
      print_error "Method chain too long in $file"
      print_info "Why: Hard to debug, breaks single responsibility" 2
      print_info "Fix: Split into intermediate variables (max 4 chains)" 2
      FOUND=1
      break
    fi
  done < "$file"
done < <(find src -name '*.ts')

if [[ $FOUND -eq 1 ]]; then
  exit 1
fi
