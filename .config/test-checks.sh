#!/usr/bin/env bash
set -euo pipefail

source .config/ui.sh

FAILED=0

cleanup() {
  rm -f src/violation-*.ts .config/violation-*.sh
}
trap cleanup EXIT

# Test 1: check-filesize.sh
print_line "Testing check-filesize.sh..."
printf '%s\n' {1..350} > src/violation-large.ts
if ! bash .config/check-filesize.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects large files"
else
  print_line "  ✗ Failed to detect large file"
  FAILED=1
fi

# Test 2: check-echo.sh
print_line "Testing check-echo.sh..."
cat > .config/violation-echo.sh << 'EOF'
#!/usr/bin/env bash
echo "this is a violation"
EOF
if ! bash .config/check-echo.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects echo usage"
else
  print_line "  ✗ Failed to detect echo"
  FAILED=1
fi

# Test 3: check-colors.sh
print_line "Testing check-colors.sh..."
print_line 'print_line -e "\033[31mred\033[0m"' > .config/violation-color.sh
if ! bash .config/check-colors.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects ANSI codes"
else
  print_line "  ✗ Failed to detect ANSI codes"
  FAILED=1
fi

# Test 4: check-pii.sh
print_line "Testing check-pii.sh..."
print_line 'const email = "test@example.com";' > src/violation-pii.ts
if ! bash .config/check-pii.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects PII patterns"
else
  print_line "  ✗ Failed to detect PII"
  FAILED=1
fi

# Test 5: check-language.sh
print_line "Testing check-language.sh..."
print_line 'const message = "hallo wereld";' > src/violation-dutch.ts
if ! bash .config/check-language.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects Dutch words"
else
  print_line "  ✗ Failed to detect Dutch"
  FAILED=1
fi

# Test 6: check-search.sh
print_line "Testing check-search.sh..."
print_line 'grep -r "pattern" src/' > .config/violation-search.sh
if ! bash .config/check-search.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects grep -r usage"
else
  print_line "  ✗ Failed to detect grep -r"
  FAILED=1
fi

# Test 7: check-comments.sh (requires cloc)
if command -v cloc >/dev/null 2>&1; then
  print_line "Testing check-comments.sh..."
  cat > src/violation-comments.ts << 'EOF'
function a() { return 1; }
function b() { return 2; }
function c() { return 3; }
function d() { return 4; }
function e() { return 5; }
EOF
  if ! bash .config/check-comments.sh >/dev/null 2>&1; then
    print_line "  ✓ Detects low comment ratio"
  else
    print_line "  ✗ Failed to detect low comments"
    FAILED=1
  fi
else
  print_line "Testing check-comments.sh..."
  print_line "  ⊘ Skipped (cloc not installed)"
fi

# Test 8: check-complexity.sh (currently no-op)
print_line "Testing check-complexity.sh..."
if bash .config/check-complexity.sh >/dev/null 2>&1; then
  print_line "  ⊘ No violations (not implemented)"
else
  print_line "  ✗ Unexpected failure"
  FAILED=1
fi

# Test 9: check-async.sh
print_line "Testing check-async.sh..."
cat > src/violation-async.ts << 'EOF'
const x = promise.then(() => {});
const y = new Promise((resolve) => resolve(1));
EOF
if ! bash .config/check-async.sh >/dev/null 2>&1; then
  print_line "  ✓ Detects promise patterns"
else
  print_line "  ✗ Failed to detect promises"
  FAILED=1
fi

if [[ $FAILED -eq 1 ]]; then
  printf "\n"
  print_line "Some checks failed to detect violations"
  exit 1
fi

printf "\n"
print_line "All checks correctly detect violations"
