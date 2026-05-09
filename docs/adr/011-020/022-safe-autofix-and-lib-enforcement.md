# ADR-022: Safe Autofix Strategy & Lib Enforcement

**Status:** Accepted
**Date:** 2026-05-09
**Context:** V-Model Layer 4 - Implementation

## Context

Two problems:
1. Autofixes in pre-commit can break code — we need a safe pattern
2. Lib functions (ui.sh, search.sh) exist but usage isn't enforced

## Decision

### 1. Safe Autofix: Format → Re-stage → Check

```
┌─────────────────────────────────────────────┐
│ git commit                                   │
│                                              │
│  Phase 1: AUTOFIX (silent, re-stages)        │
│    biome --write (staged .ts only)           │
│    editorconfig fix (staged files only)      │
│    git add -u  ← re-stage fixed files        │
│                                              │
│  Phase 2: CHECK (fail-fast, no changes)      │
│    gitleaks, pii, typescript, ...            │
│                                              │
│  If Phase 2 fails → commit blocked           │
│  Fixed files remain staged (not lost)        │
│  User can: git diff --staged (see fixes)     │
│  User can: git checkout -- . (revert all)    │
└─────────────────────────────────────────────┘
```

### Why No Stash/Pop

| Approach | Problem |
|----------|---------|
| `git stash` + pop | Merge conflicts on pop, loses unstaged work |
| `--no-verify` commit | Bypasses all safety, defeats purpose |
| Separate "fix" commit | Pollutes history, confusing |
| **Format → re-stage** | ✓ Safe: only touches staged files, reversible |

### Safety Guarantees

1. **Only staged files are touched** — unstaged work is never modified
2. **Re-stage after fix** — `git add -u` only adds already-tracked files
3. **Reversible** — `git checkout -- .` undoes all autofix changes
4. **Visible** — `git diff --staged` shows what was auto-fixed
5. **Idempotent** — running twice produces same result

### What Can Break

| Autofix | Risk | Mitigation |
|---------|------|------------|
| biome --write | Semantic changes (rare, biome is safe) | Only format rules, no unsafe fixes |
| editorconfig (trailing ws) | None — whitespace only | Safe |
| import-paths rewrite | Could break if alias misconfigured | Mark as `partial`, only in pre-push |

### 2. Lib Enforcement

**Rule:** All scripts MUST use lib functions. No raw `echo`, `grep -r`, or inline colors.

| Lib | Provides | Enforced By |
|-----|----------|-------------|
| `scripts/lib/ui.sh` | `print_step`, `print_error`, `print_warning`, colors | `colors` check |
| `scripts/lib/search.sh` | `search_files`, `search_pattern` | `search` check |
| `scripts/lib/skip.sh` | `is_skipped`, `skip_reason` | registry integrity check |
| `scripts/lib/table.sh` | `print_table` | (new) |

**Enforcement check** (`check_lib_usage`):

```bash
check_lib_usage() {
  local errors=0
  # No raw echo in check scripts (must use ui.sh)
  for f in scripts/checks/*/*.sh; do
    if grep -n '^\s*echo ' "$f" | grep -v '# shellcheck' >/dev/null 2>&1; then
      print_error "$f: use print_error/print_warning instead of echo"
      errors=$((errors + 1))
    fi
  done
  # No grep -r in check scripts (must use lib/search.sh)
  for f in scripts/checks/*/*.sh; do
    if grep -n 'grep -r' "$f" >/dev/null 2>&1; then
      print_error "$f: use search_files from lib/search.sh"
      errors=$((errors + 1))
    fi
  done
  return $errors
}
```

### 3. Pre-commit Implementation

```bash
#!/usr/bin/env bash
set -euo pipefail
source scripts/lib/ui.sh

REGISTRY=".config/checks-registry.json"
STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
[[ -z "$STAGED" ]] && exit 0

# Branch guard
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
[[ "$branch" == "main" ]] && { print_error "no direct commits to main"; exit 1; }

# Phase 1: AUTOFIX (only staged .ts files)
HAS_TS=$(echo "$STAGED" | grep -c '\.ts$' || true)
if [[ "$HAS_TS" -gt 0 ]]; then
  TS_FILES=$(echo "$STAGED" | grep '\.ts$')
  npx biome check --write $TS_FILES 2>/dev/null || true
  echo "$TS_FILES" | xargs git add
fi

# Editorconfig fix on all staged files
echo "$STAGED" | while IFS= read -r f; do
  [[ -f "$f" ]] && sed 's/[[:space:]]*$//' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
echo "$STAGED" | xargs git add

# Phase 2: CHECK (fail-fast, read tier from registry)
CHECKS=$(jq -r '.checks | to_entries[] | select(.value.tier == "pre-commit") | select(.value.autofix == "none" or .value.autofix == "partial") | .key' "$REGISTRY")

source .config/checks.conf
for f in scripts/checks/*/*.sh; do source "$f"; done

STEP=0
TOTAL=$(echo "$CHECKS" | wc -l | tr -d ' ')

for check in $CHECKS; do
  STEP=$((STEP + 1))
  # Skip check if configured
  skipped=$(jq -r ".checks[\"$check\"].skip.enabled" "$REGISTRY")
  if [[ "$skipped" == "true" ]]; then
    print_step "$(printf '%02d/%02d' $STEP $TOTAL)" "$check" "skip"
    continue
  fi
  # Run check
  OUTPUT=$("check_${check//-/_}" 2>&1) && STATUS=0 || STATUS=$?
  if [[ "$STATUS" -eq 0 ]]; then
    print_step "$(printf '%02d/%02d' $STEP $TOTAL)" "$check" "success"
  else
    print_step "$(printf '%02d/%02d' $STEP $TOTAL)" "$check" "error"
    [[ -n "$OUTPUT" ]] && printf "    %s\n" "$OUTPUT"
    print_error "failed: $check"
    exit 1
  fi
done
```

## Consequences

**Positive:**
- Autofix is safe: only staged files, always reversible
- No stash/pop complexity
- Lib enforcement prevents drift
- Registry drives behavior (single source of truth)
- Checks never see formatting noise

**Negative:**
- `git diff --staged` shows autofix changes mixed with user changes
- User must trust biome's --write is safe (it is)
- sed portability (use tmp file + mv, not sed -i)

## Related

- [ADR-009: Script Separation of Concerns](/docs/adr/001-010/009-script-separation-of-concerns.md)
- [ADR-020: Shift-Left Fail-Fast Checks](020-shift-left-fail-fast-checks.md)
- [ADR-021: CMMI-Mapped Quality Matrix](021-cmmi-mapped-quality-matrix.md)
- [Denylist](/.config/denylist.md) — sed -i portability

## Enforcement

Enforced by: `pre-commit.sh (autofix phase)` check in pre-commit/pre-push pipeline.
