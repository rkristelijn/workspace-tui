# workspace-tui — Agent Instructions

## Project

Terminal UI for workspace management (Google, Microsoft, Proton, Apple).
TypeScript + pnpm + biome + vitest. Runs over SSH.

## Quality Framework

This project uses a **process-driven CMMI maturity model** with automated enforcement.
Current level: **CMMI 1 — Managed** (run `make maturity` to verify).

### Single Source of Truth

`.config/checks-registry.json` — governs ALL check behavior:
- Which tier each check runs in (pre-commit / pre-push / ci)
- Which Makefile gates include it (check-fast / check / check-all)
- Autofix capability (full / partial / none)
- CMMI level assignment
- Skip status with expiry dates

### Three-Tier Check System

| Command | What | Speed |
|---------|------|-------|
| `make check-fast` | Format + fast lint (CMMI 0+1) | < 3s |
| `make check` | + structural/architectural (CMMI 2) | < 15s |
| `make check-all` | + CI-level optimization (CMMI 3) | < 2min |

### Pre-commit Flow (safe autofix)

1. **Autofix** — biome --write + editorconfig on staged files only
2. **Re-stage** — git add fixed files
3. **Check** — fail-fast, registry-driven, file-type aware
4. Revert autofix: `git checkout -- .`

### Process Rules (ADR-023)

Branch type = contract:
- `fix/` → reference the bug, add test covering it
- `feat/` → motivation first, test-first, verify against intent
- `refactor/` → state goal, no new files, no behavior change
- `docs/` → no .ts changes
- `chore/` → tooling only, no business logic
- `spike/` → exploration, relaxed rules

### Key Commands

```bash
make maturity          # CMMI score + level
make log              # Historical check runs (timestamp + hash)
make skip-status       # Show tech debt (skipped checks)
make skip check=X reason="..."   # Skip with 30-day expiry
make unskip check=X   # Re-enable after fix
make check-fast       # Quick validation (AI loop)
make check            # Full pre-push gate
make check-all        # Everything
make framing          # Positive language check
```

## Architecture

```
scripts/
  lib/ui.sh            # Presentation layer (ALL output goes through here)
  lib/search.sh        # Centralized file search
  lib/skip.sh          # Skip logic (reads registry)
  lib/table.sh         # Table formatting
  maturity-score.sh    # CMMI maturity calculator
  git/pre-commit.sh    # Registry-driven, safe autofix
  git/pre-push.sh      # Pre-push tier only (not duplicate of pre-commit)
  checks/
    format/            # Autofix checks (biome, editorconfig)
    code/              # Code quality (typescript, complexity, comments, etc.)
    structure/         # Architecture (filesize, deps, interface-segregation)
    security/          # Safety (gitleaks, pii, dangerous-patterns)
    quality/           # Process (coverage, traceability, workflow, docs)

.config/
  checks-registry.json # THE source of truth for all checks
  checks.conf          # Thresholds (MAX_SOURCE_LINES, MIN_COMMENT_RATIO)
  denylist.md          # Tools that don't work (stty, sed -i, grep -P, etc.)

docs/adr/             # Architectural decisions (numbered, grouped by 10)
```

## Conventions

- **No raw echo/printf** in check scripts — use `ui.sh` functions
- **No grep -r** in checks — use `lib/search.sh`
- **No sed -i** — use tmp file + mv (macOS/Linux portable)
- **No stty size** — use `${COLUMNS:-80}`
- **No network calls** in pre-commit — move to CI
- Checks communicate via stdout protocol: `SKIP: reason` for skips
- All scripts reference their ADR: `# @see docs/adr/...`

## Positive Framing

When reporting issues, frame positively:
- ✓ "15/24 checks active (62%)" not "9 checks failing"
- ✓ "CMMI 1 achieved, 4 items to CMMI 2" not "not at CMMI 2 yet"
- ✓ "Coverage growing: 54% → 57%" not "coverage below target"

## ADRs (key decisions)

- ADR-020: Shift-left fail-fast check strategy (3-tier, smart file detection)
- ADR-021: CMMI-mapped quality matrix (checks → CMMI levels)
- ADR-022: Safe autofix strategy (format → re-stage → check)
- ADR-023: Process-driven maturity model (branch type = workflow contract)

## Working on This Project

1. Read `make maturity` to understand current state
2. Read `make skip-status` to see tech debt
3. Use `make check-fast` as your feedback loop while coding
4. Run `make check` before pushing
5. When fixing a skip: unskip → verify check passes → commit

## Logging

Every pre-commit and pre-push run is logged to `.tmp/checks.log` with:
- ISO timestamp
- Commit hash (for time-travel)
- Branch name
- Gate that ran
- Pass/fail
- Active checks count at that moment

Use `make log` to see history. This tracks maturity progression over time.

## Known Issues (tech debt via skip-status)

Run `make skip-status` for current list. Each has an expiry date.
Fix one → `make unskip check=X` → maturity score rises.
