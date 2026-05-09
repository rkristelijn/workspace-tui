# ADR-020: Shift-Left Fail-Fast Check Strategy

**Status:** Accepted
**Date:** 2026-05-09
**Context:** V-Model Layer 4 - Implementation
**Supersedes:** Partially updates ADR-014

## Context

During vibe coding with AI agents, the pre-commit hook runs all 24 checks sequentially regardless of which files changed. This takes too long and provides no early exit on failure. The pre-push hook is identical to pre-commit (no differentiation). Reference: llama-cli's 3-tier system with smart file detection.

## Problem

| Issue | Impact |
|-------|--------|
| All 24 checks run on every commit | Slow feedback (~15s+) |
| No file-type awareness | Runs TS checks on .md changes |
| Pre-push = pre-commit (identical) | No layered defense |
| No CI pipeline | No final safety net |
| 9 checks skipped | Hidden tech debt |
| `stty size` in non-TTY | Breaks in CI/pipes |
| Heavy checks in pre-commit | Coverage runs on every commit |

## Decision

### 1. Three-Tier Check System (like llama-cli)

```
Pre-commit (< 3s)     → Format + fast lint + security
Pre-push   (< 15s)    → Build + test + integrity
CI         (< 2min)   → Full suite + coverage + audit
```

### 2. Smart File Detection in Pre-commit

Only run checks relevant to staged files:

```bash
# Detect staged file types
HAS_TS=$(git diff --cached --name-only | grep -q '\.ts$' && echo 1 || echo 0)
HAS_SH=$(git diff --cached --name-only | grep -q '\.sh$' && echo 1 || echo 0)
HAS_MD=$(git diff --cached --name-only | grep -q '\.md$' && echo 1 || echo 0)
HAS_JSON=$(git diff --cached --name-only | grep -q '\.json$' && echo 1 || echo 0)
```

### 3. Check Tier Assignment

| Tier | Checks | Trigger |
|------|--------|---------|
| **Pre-commit** | biome, typescript, editorconfig, gitleaks, pii, no-hardcoded-secrets, dangerous-patterns, filenames, clean-root | Every commit |
| **Pre-push** | + filesize, complexity, comments, deps, types-colocation, interface-segregation, import-paths | Before push |
| **CI** | + coverage, traceability, language, emoji, async, docs, colors, search | PR/merge |

### 4. Fail-Fast Order (fastest checks first)

Pre-commit order:
1. `biome` (has autofix, instant)
2. `editorconfig` (instant)
3. `filenames` (instant, no I/O)
4. `clean-root` (instant, no I/O)
5. `gitleaks` (fast, critical)
6. `no-hardcoded-secrets` (fast, critical)
7. `pii` (fast, critical)
8. `dangerous-patterns` (fast)
9. `typescript` (slower, needs tsc)

### 5. Tool Denylist

Tools that don't work reliably in our context:

| Tool/Pattern | Problem | Alternative |
|--------------|---------|-------------|
| `stty size` | Fails in non-TTY (CI, pipes, SSH) | `${COLUMNS:-80}` or `tput cols 2>/dev/null \|\| echo 80` |
| `tput` colors in pipes | Garbled output when piped | Check `[[ -t 1 ]]` before colors |
| `grep -P` (PCRE) | Not available on macOS default grep | `grep -E` (extended regex) |
| `readarray`/`mapfile` | bash 4+ only, macOS ships bash 3 | `while IFS= read -r` loop |
| `sed -i ''` vs `sed -i` | macOS vs Linux incompatibility | Use temp file + mv |
| `date +%s%N` | macOS date has no nanoseconds | `date +%s` (seconds sufficient) |
| `realpath` | Not on all macOS | `cd "$(dirname "$0")" && pwd` |
| `xargs -d` | GNU only | `xargs` with `-0` or pipe |
| `find -regex` | Syntax differs macOS/Linux | `find -name` with multiple patterns |
| `npm audit` in pre-commit | Network-dependent, slow | Move to CI only |

### 6. Autofix Strategy

Checks with autofix run silently and re-stage:

```bash
# Autofix checks: run --write, then re-stage
if [[ "$HAS_TS" == "1" ]]; then
  npx biome check --write --staged 2>/dev/null
  git add -u  # re-stage fixed files
fi
```

| Check | Autofix | Method |
|-------|---------|--------|
| biome | ✓ | `biome check --write` |
| editorconfig | ✓ | Trim trailing whitespace, fix EOL |
| filenames | ✗ | Rename requires user decision |
| gitleaks | ✗ | Secret removal is manual |
| typescript | ✗ | Type errors need human fix |
| import-paths | ✓ | Rewrite relative → alias |

## Implementation

### New Pre-commit (simplified)

```bash
#!/usr/bin/env bash
set -euo pipefail
source scripts/lib/ui.sh
source .config/checks.conf

# Branch guard
branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
[[ "$branch" == "main" ]] && { print_error "no direct commits to main"; exit 1; }

# Smart detection
STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
[[ -z "$STAGED" ]] && exit 0

HAS_TS=$(echo "$STAGED" | grep -q '\.ts$' && echo 1 || echo 0)
HAS_SH=$(echo "$STAGED" | grep -q '\.sh$' && echo 1 || echo 0)

# Phase 1: Autofix (silent)
[[ "$HAS_TS" == "1" ]] && npx biome check --write $(echo "$STAGED" | grep '\.ts$') 2>/dev/null && git add -u

# Phase 2: Fast checks (fail-fast)
for check in gitleaks pii no-hardcoded-secrets dangerous-patterns; do
  run_check "$check" || exit 1
done

# Phase 3: Type checks (only if TS changed)
[[ "$HAS_TS" == "1" ]] && run_check typescript || exit 1
```

### New Pre-push (integrity)

```bash
#!/usr/bin/env bash
set -euo pipefail
# Heavier checks: build verification + structural integrity
CHECKS=(filesize complexity comments deps interface-segregation import-paths)
```

## Consequences

**Positive:**
- Pre-commit drops from ~15s to < 3s
- Only relevant checks run per file type
- Autofix reduces manual work
- Clear tier separation prevents duplicate work
- Denylist prevents recurring tool issues

**Negative:**
- Some checks move to later stages (less shift-left for those)
- Smart detection adds complexity to hook
- Need to maintain tier assignment table

## Migration

1. Update `scripts/git/pre-commit.sh` with smart detection
2. Create `scripts/git/pre-push.sh` with integrity checks
3. Add `.config/denylist.md` for tool issues
4. Update Makefile with `check-fast` / `check` / `check-all` targets
5. Remove coverage from pre-commit (move to CI)

## Related

- [ADR-014: Git Workflow Quality Gates](014-git-workflow-quality-gates.md)
- [ADR-019: Quality Check Skip Configuration](019-quality-check-skip-configuration.md)
- [ADR-010: Filesize Complexity Limits](/docs/adr/001-010/010-filesize-complexity-limits.md)
