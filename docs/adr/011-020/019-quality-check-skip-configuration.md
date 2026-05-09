# ADR-019: Quality Check Skip Configuration

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 4 - Implementation

## Context

Quality checks must be enforced, but sometimes files temporarily violate rules during refactoring. We need a way to acknowledge violations without disabling checks globally.

## Problem

Without skip mechanism:
- Can't push code during large refactors
- Temptation to disable checks permanently
- No visibility into what's skipped
- No accountability for fixing violations

## Decision

**Implement explicit, tracked skip configuration in `.config/checks-skip.json`**

### Why

1. **Transparency** - All skips are visible in one place
2. **Accountability** - Skips require reason and tracking
3. **Temporary** - Skips are meant to be removed
4. **Auditable** - Coverage check shows what's skipped

### What

JSON configuration file that allows skipping specific checks for specific files:

```json
{
  "skip": {
    "filesize": {
      "enabled": true,
      "reason": "Files need splitting - tracked in TODO.md",
      "files": [
        "src/providers/google/index.ts",
        "src/cli.ts"
      ]
    },
    "complexity": {
      "enabled": false,
      "reason": "Example: disabled skip",
      "files": []
    }
  }
}
```

### How

#### 1. Configuration Structure

```json
{
  "skip": {
    "<check-name>": {
      "enabled": boolean,      // Is skip active?
      "reason": string,        // Why is this skipped?
      "files": string[],       // Which files to skip
      "expires": string?       // Optional: ISO date when skip expires
    }
  }
}
```

#### 2. Check Script Integration

Each check script reads skip config:

```bash
check_example() {
  local skip_config=".config/checks-skip.json"
  local skip_enabled=false
  local skip_files=()
  
  # Load skip config
  if [[ -f "$skip_config" ]]; then
    skip_enabled=$(jq -r '.skip.example.enabled // false' "$skip_config")
    if [[ "$skip_enabled" == "true" ]]; then
      mapfile -t skip_files < <(jq -r '.skip.example.files[]?' "$skip_config")
    fi
  fi
  
  # Check if file should be skipped
  for skip_file in "${skip_files[@]}"; do
    [[ "$file" == "$skip_file" ]] && {
      print_warning "$file: violation - SKIPPED"
      continue
    }
  done
}
```

#### 3. Coverage Reporting

Coverage check shows skip status:

```
structure/
  filesize (SKIP)           ✓           ✓           ~           ~
```

#### 4. Workflow

1. **Violation occurs** - Check fails
2. **Add to skip config** - With reason
3. **Add to TODO.md** - Track as technical debt
4. **Fix violation** - In separate PR
5. **Remove from skip** - Clean up config

## Rules

### When to Skip

✅ **Allowed:**
- Large refactoring in progress
- External dependency issues
- Temporary workaround for urgent fix

❌ **Not Allowed:**
- Permanent violations
- Laziness
- "We'll fix it later" without tracking

### Requirements

1. **Must have reason** - Why is this skipped?
2. **Must be tracked** - Add to TODO.md
3. **Must be temporary** - Plan to fix
4. **Must be reviewed** - Skip config in PR review

### Expiration

Optional `expires` field:

```json
{
  "skip": {
    "filesize": {
      "enabled": true,
      "reason": "Refactoring in progress",
      "files": ["src/large-file.ts"],
      "expires": "2026-06-01"
    }
  }
}
```

Check script can warn if expired.

## Consequences

**Positive:**
- Enables incremental refactoring
- Maintains visibility into violations
- Prevents permanent check disabling
- Self-documenting technical debt
- Auditable in coverage report

**Negative:**
- Adds configuration complexity
- Requires discipline to remove skips
- Can be abused if not reviewed
- Needs jq dependency

## Implementation

### Files

- `.config/checks-skip.json` - Skip configuration
- `scripts/checks/*/` - Each check reads config
- `scripts/checks/quality/coverage.sh` - Shows skip status
- `TODO.md` - Tracks skipped items as debt

### Validation

Coverage check fails if:
- Skip has no reason
- Skip has no files
- Skip is enabled but files array empty

## Related

- [ADR-010: Filesize Complexity Limits](/docs/adr/001-010/010-filesize-complexity-limits.md)
- [ADR-014: Git Workflow Quality Gates](/docs/adr/011-020/014-git-workflow-quality-gates.md)
- [Workflow](/docs/process/workflow.md)

## Enforcement

Enforced by: `skip (make skip/unskip)` check in pre-commit/pre-push pipeline.
