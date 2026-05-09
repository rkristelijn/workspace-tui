#!/usr/bin/env bash
# Enforce workflow per branch type.
# fix/ → must reference bug. feat/ → must have tests. refactor/ → no new files.
# @see docs/adr/011-020/023-process-driven-maturity-model.md
check_workflow() {
  local branch
  branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
  [[ -z "$branch" ]] && return 0

  local branch_type="${branch%%/*}"
  local staged
  staged=$(git diff --cached --name-only 2>/dev/null || true)
  [[ -z "$staged" ]] && return 0

  case "$branch_type" in
    fix)
      # Must have test changes if fixing src/
      local has_src=$(echo "$staged" | grep -c '^src/.*\.ts$' || true)
      local has_test=$(echo "$staged" | grep -c '\.test\.' || true)
      if [[ "$has_src" -gt 0 && "$has_test" -eq 0 ]]; then
        print_warning "fix/ branch: consider adding a test that covers the bug"
      fi
      ;;
    feat)
      # Must have test changes if adding src/ code
      local has_src=$(echo "$staged" | grep -c '^src/.*\.ts$' || true)
      local has_test=$(echo "$staged" | grep -c '\.test\.' || true)
      if [[ "$has_src" -gt 0 && "$has_test" -eq 0 ]]; then
        print_warning "feat/ branch: add tests for new code (test-first)"
      fi
      ;;
    refactor)
      # Should not add new src/ files (behavior unchanged)
      local new_files=$(git diff --cached --name-only --diff-filter=A | grep -c '^src/.*\.ts$' || true)
      if [[ "$new_files" -gt 0 ]]; then
        print_warning "refactor/ branch: adding new src/ files suggests this is a feat/"
      fi
      ;;
    docs)
      # No .ts changes
      if echo "$staged" | grep -q '\.ts$'; then
        print_warning "docs/ branch: should not modify .ts files"
      fi
      ;;
  esac
  return 0  # Warnings only at Level 2, blocking at Level 3
}
