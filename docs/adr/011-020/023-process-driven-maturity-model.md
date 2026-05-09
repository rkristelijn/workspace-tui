# ADR-023: Process-Driven Maturity Model

**Status:** Accepted
**Date:** 2026-05-09
**Context:** V-Model Layer 2 - Design
**Supersedes:** Reframes ADR-021 (checks are enforcement, not the model itself)

## Context

ADR-021 mapped checks to CMMI levels, but CMMI is about **process maturity**, not tooling. A project with 100 passing checks but no defined workflow is still CMMI 1. The real question: "Is the way of working defined, followed, and enforced?"

## Insight

```
Process defines → what you must do
Checks enforce  → that you did it
Maturity grows  → when process becomes habit
```

The checks are *evidence* of process adherence, not the process itself.

## Decision

### Maturity = Process Compliance, Not Check Count

| Level | Name | Process Requirement | Enforcement |
|-------|------|-------------------|-------------|
| **1** | Initial | Make it work. Checks pass. | Pre-commit checks |
| **2** | Managed | Every change has a *reason* and follows a *workflow* per type | Commit-msg + branch type → required artifacts |
| **3** | Defined | Design before build. Test before code. Verify against intent. | ADR exists before code, test file before impl |
| **4** | Measured | Feature coverage tracked. Traceability complete. | Markers, e2e coverage map |
| **5** | Optimizing | Process itself improves. Retrospectives automated. | Delta reports, pattern detection |

### Level 2: Managed Workflow (our next target)

Every change MUST have a reason. The branch type determines the required workflow:

| Branch Type | Required Workflow | Enforced How |
|-------------|------------------|--------------|
| `fix/` | Issue/bug exists → fix → test covers the bug → close | Commit msg references issue |
| `feat/` | Motivation → ADR (if architectural) → test-first → build → verify | ADR or TODO item exists |
| `refactor/` | Goal stated → refactor → verify goal met → no behavior change | Tests pass before AND after |
| `docs/` | Content only, no code changes | No .ts files in diff |
| `chore/` | Tooling/config, no business logic | No src/ business logic changes |

**Key rule:** If you change code without a `fix/` or `feat/` branch, you're freestyling. That's Level 1.

### Level 3: Defined (Design-First)

| Step | What | Evidence |
|------|------|----------|
| 1. Motivate | Why are we doing this? | ADR or issue with value statement |
| 2. Design | How will it work? | Test file created (empty/skeleton) |
| 3. Build | Make it work | Implementation passes tests |
| 4. Verify | Did we do what we said? | ADR acceptance criteria met |

**Enforcement:** Pre-push checks that:
- `feat/` branch has a corresponding test file modified
- New src/ files have a test file
- ADR referenced in commit if architectural change

### Level 4: Measured

| What | How |
|------|-----|
| Feature coverage | E2E tests have `@feature` markers, script counts coverage |
| Traceability | ADR → issue → branch → test → code (bidirectional) |
| Process metrics | Time from branch create to merge, rework rate |

### Level 5: Optimizing

| What | How |
|------|-----|
| Pattern detection | "You've written 3 similar functions, consider abstraction" |
| Positive framing | Celebrate what went well, not just what failed |
| Process improvement | Retrospective generates ADR updates automatically |

## Implementation: Level 2 Enforcement

### Commit Message Convention

```
type(scope): description

Refs: #issue or ADR-XXX
```

**Enforcement in pre-commit:**
```bash
# Branch type must match commit type
branch_type="${branch%%/*}"
commit_type=$(head -1 "$COMMIT_MSG_FILE" | cut -d'(' -f1 | cut -d':' -f1)
[[ "$branch_type" == "$commit_type" ]] || warn "branch type ≠ commit type"
```

### Branch-Type Workflow Checks

```bash
check_workflow_compliance() {
  local branch_type="${branch%%/*}"
  case "$branch_type" in
    fix)
      # Must reference an issue or describe the bug
      git log --oneline -1 | grep -qiE '#[0-9]+|fixes|bug' || {
        print_warning "fix/ branch: reference the bug (Fixes #N)"
        return 1
      }
      ;;
    feat)
      # Must have test changes if src/ changes
      local has_src=$(git diff --cached --name-only | grep -c '^src/' || true)
      local has_test=$(git diff --cached --name-only | grep -c '\.test\.' || true)
      [[ "$has_src" -gt 0 && "$has_test" -eq 0 ]] && {
        print_warning "feat/ branch: add tests for new code"
        return 1
      }
      ;;
    refactor)
      # No new exports, no new files (behavior unchanged)
      local new_files=$(git diff --cached --name-only --diff-filter=A | grep -c '^src/' || true)
      [[ "$new_files" -gt 0 ]] && {
        print_warning "refactor/ branch: should not add new src/ files"
        return 1
      }
      ;;
    docs)
      # No .ts changes
      git diff --cached --name-only | grep -q '\.ts$' && {
        print_warning "docs/ branch: should not modify .ts files"
        return 1
      }
      ;;
  esac
  return 0
}
```

### Make It Work → Make It Better

The philosophy: **a check that warns is better than no check at all.**

1. New check starts as `print_warning` (advisory)
2. Once the team follows it naturally → promote to `print_error` (blocking)
3. This IS the optimizing loop (Level 5 behavior at any level)

Example: `dangerous-patterns` started blocking `eval()` + `@ts-ignore`. Later we add `as` assertions when the codebase is ready. The check grows with the project.

## llama-cli Assessment

| Aspect | Status | Level |
|--------|--------|-------|
| Checks pass | ✓ 100+ checks | 1 |
| Branch naming enforced | ✓ | 1 |
| Commit msg convention | ✓ (commitlint) | 2 |
| Workflow per branch type | ✗ not enforced | 1 |
| Test-first enforced | ✗ | 1 |
| ADR before code | ✗ (ADRs exist but not required before code) | 1 |
| Feature coverage tracking | ✗ | 1 |
| Traceability | Partial (ADR refs in code) | 1-2 |

**Verdict: llama-cli is CMMI 1 with CMMI 2 aspirations.** It has the tooling for Level 2 but doesn't enforce the *process*. You can still push code without an ADR, without tests, without referencing an issue.

## Consequences

**Positive:**
- Process is the driver, checks are the enforcement
- Clear growth path: fix workflow → checks follow
- "Make it work → make it better" prevents perfectionism paralysis
- Branch type = contract about what you're doing

**Negative:**
- Workflow checks can feel restrictive during exploration
- Need escape hatch for spikes (`spike/` branch type with relaxed rules?)
- Solo dev must self-discipline (AI agents help enforce)

## The Balance

> "Doing things right" (operational) vs "Doing the right things" (tactical)

The answer: **branch type declares your intent.** If you're on `feat/streaming`, you committed to the feat workflow. If you want to explore, use `spike/explore-streaming` with relaxed rules. The process adapts to your intent, not the other way around.

## Related

- [ADR-021: CMMI-Mapped Quality Matrix](021-cmmi-mapped-quality-matrix.md)
- [ADR-014: Git Workflow Quality Gates](014-git-workflow-quality-gates.md)
- llama-cli ADR-048: Lean Quality Framework
- llama-cli ADR-003: V-Model Workflow
