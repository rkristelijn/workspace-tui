# ADR-011: Script Architecture - Separation of Concerns

*Status*: Accepted · *Date*: 2026-05-08

## Context

Shell scripts in `.config/` were mixing presentation and logic:
- Hardcoded colors and formatting
- Duplicate output patterns
- Inconsistent error messages
- Direct `echo` statements everywhere
- Hard to maintain and test

## Decision

Implement strict separation of concerns for shell scripts:

**Layers:**
1. **Presentation** - `.config/ui.sh` (UI utilities)
2. **Logic** - Individual scripts (business logic only)
3. **Data** - Config files (patterns, words, etc.)

**Rules:**
- ❌ No `echo` in logic scripts
- ❌ No color codes in logic scripts
- ❌ No formatting in logic scripts
- ✅ Use `ui.sh` functions for all output
- ✅ Return exit codes (0 = success, 1 = error)
- ✅ Keep logic scripts focused on one task

## Architecture

```
.config/
  ui.sh                    # Presentation layer
  pre-commit               # Orchestration (uses ui.sh)
  check-pii.sh             # Logic only (no echo)
  check-language.sh        # Logic only (no echo)
  search.sh                # Utility (no echo)
  
  dutch-words.txt          # Data
  passive-voice.txt        # Data
  .pii                     # Data
```

## UI Layer (`.config/ui.sh`)

**Colors:**
```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
RESET='\033[0m'
```

**Symbols:**
```bash
CHECK="✓"
CROSS="✗"
SKIP="⊘"
```

**Functions:**
```bash
print_step "1/5" "biome" "success" "2s"
print_section "Formatting"
print_error "Branch name invalid"
print_warning "Passive voice detected"
print_summary "5s"
```

## Logic Layer

**Before (mixed concerns):**
```bash
printf "  [1/5] biome... "
if pnpm lint > /dev/null 2>&1; then
  echo "✓"
else
  echo "✗"
  exit 1
fi
```

**After (separated):**
```bash
source .config/ui.sh

if pnpm lint > /dev/null 2>&1; then
  print_step "1/5" "biome" "success" "2s"
else
  print_step "1/5" "biome" "error"
  exit 1
fi
```

## Enforcement

**Linting rule:**
Check scripts for direct `echo` usage (except `ui.sh`):

```bash
# In pre-commit or CI
if grep -r "echo " .config/*.sh | grep -v "ui.sh"; then
  echo "ERROR: Use ui.sh functions instead of echo"
  exit 1
fi
```

**Code review:**
- Reject PRs with `echo` in logic scripts
- Require `source .config/ui.sh` at top of orchestration scripts

## Benefits

**Maintainability:**
- Change colors in one place
- Consistent output format
- Easy to add new status types

**Testability:**
- Logic scripts return exit codes
- No output parsing needed
- Mock UI layer for tests

**Readability:**
- Clear intent: `print_error()` vs `echo -e "${RED}ERROR${RESET}"`
- Self-documenting code
- Less visual noise

## Examples

**Status types:**
```bash
print_step "1/5" "biome" "success" "2s"   # ✓ (2s)
print_step "2/5" "gitleaks" "error"       # ✗
print_step "3/5" "semgrep" "skip" "not installed"  # ⊘ (not installed)
print_step "4/5" "emoji" "fixed" "removed, 1s"     # ✓ (removed, 1s)
```

**Sections:**
```bash
print_section "Formatting"
# -- Formatting --

print_section "Security"
# -- Security --
```

**Messages:**
```bash
print_error "Branch name invalid"
# ERROR: Branch name invalid

print_warning "Passive voice detected"
# WARNING: Passive voice detected
```

## Consequences

**Positive:**
- Consistent UI across all scripts
- Easy to change colors/symbols
- Testable logic scripts
- Clear separation of concerns
- Self-documenting code

**Negative:**
- Requires sourcing `ui.sh`
- One more abstraction layer
- Slightly more verbose

**Migration:**
All existing scripts refactored to use `ui.sh`.

## References

- [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) - Do one thing well
- [Separation of Concerns](https://en.wikipedia.org/wiki/Separation_of_concerns)
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) - Single Responsibility Principle

## Enforcement

- `scripts/checks/colors.sh`
- `scripts/checks/filesize.sh`
