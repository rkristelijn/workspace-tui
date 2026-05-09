# ADR-014: Git Workflow Quality Gates

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 5 - Implementation

## Context

Quality checks must run at the right time: fast checks before commit, integrity checks before push, comprehensive checks in CI. Inspired by llama-cli's layered approach.

## Decision

Three-tier quality gate system:

### 1. Pre-commit (Fast, < 5s)
**Goal:** Catch obvious errors, avoid slop  
**Checks:**
- Biome (format, lint)
- TypeScript compilation
- File size limits
- Cyclomatic complexity
- Docs structure validation
- Branch naming validation

**Philosophy:** Fast feedback loop, auto-fix where possible

### 2. Pre-push (Integrity, < 30s)
**Goal:** Verify code integrity before sharing  
**Checks:**
- All pre-commit checks
- Secret detection (gitleaks)
- PII detection
- Dangerous patterns
- Interface segregation
- Traceability (ADR references)
- Dependency validation

**Philosophy:** Prevent pushing broken/insecure code

### 3. CI Pipeline (Full, < 5min)
**Goal:** Comprehensive quality verification  
**Checks:**
- All pre-push checks
- Integration tests (if exist)
- Security audit (npm audit)
- License compliance
- Documentation completeness
- Performance benchmarks

**Philosophy:** Gate for main branch, auto-create issues for failures

## Implementation

```bash
# Pre-commit: .git/hooks/pre-commit → scripts/git/pre-commit.sh
# Pre-push:   .git/hooks/pre-push → scripts/git/pre-push.sh
# CI:         .github/workflows/quality.yml
```

### Branch Protection
- Direct commits to main: BLOCKED
- Branch naming: `type/description` (feat, fix, chore, docs, refactor, test, ci, style, perf, build)
- Main requires: PR + CI pass

### Auto-issue Creation
CI failures on main automatically create GitHub issues with:
- Failed check details
- Reproduction steps
- Suggested fixes
- Assigned to last committer

## Consequences

**Positive:**
- Fast local feedback (< 5s)
- Prevents pushing broken code
- Comprehensive CI verification
- Auto-tracked quality issues

**Negative:**
- Requires discipline to not skip hooks
- CI time adds to PR cycle
- Auto-issues need triage

## Related

- [ADR-007: English Active Voice](007-english-active-voice.md)
- [ADR-010: Filesize Complexity Limits](010-filesize-complexity-limits.md)
- [Workflow](/docs/process/workflow.md)
