# ADR-012: File Size and Complexity Limits

*Status*: Accepted · *Date*: 2026-05-08

## Context

Large files and complex functions are hard to:
- Understand
- Test
- Maintain
- Review
- Refactor

Starting with strict limits from day one prevents technical debt accumulation.

## Decision

Enforce file size and complexity limits in pre-commit:

**File Size Limits:**
- Source files: 300 lines max
- Test files: 500 lines max

**Complexity Limits:**
- Cyclomatic complexity: 10 max (future)
- Function length: 50 lines max (future)

## Rationale

**Why 300 lines for source:**
- Forces single responsibility
- Fits on one screen (with context)
- Easy to understand in one sitting
- Encourages modular design

**Why 500 lines for tests:**
- Tests need more setup/teardown
- Multiple test cases per file
- Still manageable size

**Why enforce early:**
- Easier to keep small than to split later
- Prevents "just one more function" syndrome
- Forces good architecture from start

## Implementation

`.config/check-filesize.sh`:
```bash
MAX_SOURCE=300
MAX_TEST=500

# Check all TypeScript files
find src -name '*.ts' | while read file; do
  lines=$(wc -l <"$file")
  if ((lines > max)); then
    exit 1
  fi
done
```

`.config/check-complexity.sh`:
```bash
# TODO: Implement with ts-complexity or ESLint
# For now: file size acts as proxy
```

## Enforcement

Pre-commit hook blocks commits with violations:
```
-- Formatting --
  [3/4] filesize...   ✗

ERROR: src/providers/google/index.ts has 350 lines (max 300)
  Split into smaller, focused modules
```

## Consequences

**Positive:**
- Forces modular design
- Easier code reviews
- Better testability
- Lower cognitive load
- Prevents technical debt

**Negative:**
- May feel restrictive initially
- Requires more files
- Need to think about structure upfront

**Mitigation:**
- Limits are generous (300 lines is plenty)
- Tests get more space (500 lines)
- Forces good habits early

## Examples

**Good structure:**
```
src/providers/google/
  index.ts          # 50 lines - exports
  auth.ts           # 100 lines - OAuth flow
  calendar.ts       # 150 lines - Calendar API
  email.ts          # 150 lines - Gmail API
  tasks.ts          # 100 lines - Tasks API
```

**Bad structure:**
```
src/providers/google/
  index.ts          # 550 lines - everything
```

## Future Enhancements

- Add cyclomatic complexity check (ts-complexity)
- Add function length check
- Add cognitive complexity check
- Generate complexity reports

## References

- [Cognitive Load Theory](https://en.wikipedia.org/wiki/Cognitive_load)
- [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single-responsibility_principle)
- [Code Complete](https://www.amazon.com/Code-Complete-Practical-Handbook-Construction/dp/0735619670) - recommends 200 lines max
- llama-cli: 600 lines max (C++), 300 lines max (headers)
