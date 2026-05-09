# ADR-008: Centralized Search Utility

*Status*: Accepted · *Date*: 2026-05-08

## Context

Multiple pre-commit checks need to search through code:
- PII detection
- Language/style validation
- Emoji detection
- Secret scanning

Each check was using different search methods:
- `grep -r` with manual excludes
- Different exclude patterns per check
- Code duplication
- Slow performance (scanning node_modules, dist, etc.)

## Decision

Create centralized search utility (`.config/search.sh`) that:
- Respects `.gitignore` automatically
- Uses `ripgrep` (rg) if available (10-100x faster)
- Falls back to `grep` with `.gitignore` parsing
- Single source of truth for search logic

**All checks use this utility:**
```bash
bash .config/search.sh "pattern" [paths]
```

## Implementation

**Search utility:**
```bash
# Uses ripgrep (respects .gitignore by default)
rg --no-heading --line-number "pattern" src/ docs/

# Fallback: grep with .gitignore parsing
grep -r --exclude-dir=node_modules --exclude-dir=dist "pattern" src/
```

**Checks refactored:**
- `check-pii.sh` - uses search utility
- `check-language.sh` - uses search utility
- `pre-commit` emoji check - uses search utility

## Rationale

**Why centralized:**
- DRY principle (Don't Repeat Yourself)
- Single place to update exclude logic
- Consistent behavior across all checks

**Why respect .gitignore:**
- Already defines what to ignore
- No duplicate exclude lists
- Automatically excludes build artifacts

**Why ripgrep:**
- 10-100x faster than grep
- Respects .gitignore by default
- Better regex support
- Graceful fallback to grep

## Consequences

**Positive:**
- Much faster checks (skip node_modules, dist, etc.)
- No code duplication
- Easy to maintain
- Consistent exclude logic

**Negative:**
- Requires ripgrep for best performance (optional)
- One more abstraction layer

**Performance:**
```
Before: grep scans ~50k files (including node_modules)
After:  rg scans ~100 files (respects .gitignore)
Result: 50-100x faster
```

## Installation

**macOS:**
```bash
brew install ripgrep
```

**Linux:**
```bash
apt install ripgrep  # Debian/Ubuntu
dnf install ripgrep  # Fedora
```

**Fallback:**
Works without ripgrep (uses grep).

## References

- [ripgrep](https://github.com/BurntSushi/ripgrep) - faster grep alternative
- [DRY Principle](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)

## Enforcement

- `scripts/checks/search.sh`
