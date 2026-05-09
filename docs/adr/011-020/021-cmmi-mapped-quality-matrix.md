# ADR-021: CMMI-Mapped Quality Check Matrix

**Status:** Accepted
**Date:** 2026-05-09
**Context:** V-Model Layer 3 - Design
**References:** CMMI-DEV v1.3, llama-cli ADR-048 (Lean Quality Framework)

## Context

We need a single source of truth that maps every quality check to:
1. When it runs (pre-commit / pre-push / CI / check-fast / check / check-all)
2. Whether it has autofix capability
3. Which CMMI maturity level it satisfies
4. Whether it's currently skipped (and why)

This enables a maturity score script: count active checks per CMMI level → calculate how "volwassen" the project is.

## Decision

### Single Source of Truth: `.config/checks-registry.json`

One file governs all check behavior across all runners.

```json
{
  "$schema": "./checks-registry.schema.json",
  "checks": {
    "<name>": {
      "tier": "pre-commit|pre-push|ci",
      "gates": ["check-fast", "check", "check-all"],
      "autofix": "full|partial|none",
      "cmmi": 0,
      "filetypes": ["ts", "sh", "md", "*"],
      "skip": { "enabled": false, "reason": "", "expires": "" },
      "category": "format|code|structure|security|quality"
    }
  }
}
```

### CMMI Level Mapping (from CMMI-DEV v1.3)

| CMMI | Process Area | Our Checks | Rationale |
|------|-------------|------------|-----------|
| **0 - Initial** | (none formal) | `biome`, `editorconfig`, `filenames`, `clean-root` | Basic hygiene, "make it work" |
| **1 - Managed** | CM (Config Mgmt), PPQA (QA) | `gitleaks`, `pii`, `no-hardcoded-secrets`, `dangerous-patterns`, `typescript` | Repeatable security + type safety |
| **2 - Defined** | VER (Verification), TS (Technical Solution) | `filesize`, `complexity`, `comments`, `deps`, `interface-segregation`, `import-paths`, `types-colocation`, `coverage` | Measured quality, architectural rules |
| **3 - Optimizing** | OPF (Process Focus), DAR (Decision Analysis) | `traceability`, `language`, `emoji`, `async`, `docs`, `colors`, `search` | Process optimization, consistency enforcement |

### Gate Mapping

| Gate | When | Contains | Speed |
|------|------|----------|-------|
| **pre-commit** | Every commit | CMMI 0 + CMMI 1 (security) | < 3s |
| **pre-push** | Before push | + CMMI 2 (verification) | < 15s |
| **ci** | PR/merge | + CMMI 3 (optimization) | < 2min |
| **check-fast** | `make check-fast` | pre-commit tier only | < 3s |
| **check** | `make check` | pre-commit + pre-push | < 15s |
| **check-all** | `make check-all` | Everything including CI tier | < 2min |

### Autofix Classification

| Level | Meaning | Example |
|-------|---------|---------|
| `full` | Completely auto-fixable, re-stages | biome --write, editorconfig trim |
| `partial` | Some violations fixable, some need human | import-paths (aliases yes, circular no) |
| `none` | Requires human decision | typescript errors, secret removal |

### Maturity Score Calculation

```bash
# Score = (active checks per level / total checks per level) × weight
# CMMI 0: weight 1 (foundation)
# CMMI 1: weight 2 (security/reliability)  
# CMMI 2: weight 3 (verification/architecture)
# CMMI 3: weight 4 (optimization/process)
#
# Max score = 4+10+24+28 = 66
# Current score with 9 skips = depends on which levels are skipped
```

## Implementation

### 1. Registry File

`.config/checks-registry.json` — replaces both `checks-metadata.json` and `checks-skip.json`:

```json
{
  "checks": {
    "biome":                {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"full","cmmi":0,"filetypes":["ts"],"skip":{"enabled":false},"category":"format"},
    "editorconfig":         {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"full","cmmi":0,"filetypes":["*"],"skip":{"enabled":false},"category":"format"},
    "filenames":            {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"none","cmmi":0,"filetypes":["*"],"skip":{"enabled":false},"category":"structure"},
    "clean-root":           {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"none","cmmi":0,"filetypes":["*"],"skip":{"enabled":false},"category":"structure"},
    "gitleaks":             {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"none","cmmi":1,"filetypes":["*"],"skip":{"enabled":false},"category":"security"},
    "no-hardcoded-secrets": {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"none","cmmi":1,"filetypes":["*"],"skip":{"enabled":false},"category":"security"},
    "pii":                  {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"none","cmmi":1,"filetypes":["*"],"skip":{"enabled":false},"category":"security"},
    "dangerous-patterns":   {"tier":"pre-commit","gates":["check","check-all"],"autofix":"none","cmmi":1,"filetypes":["ts"],"skip":{"enabled":true,"reason":"Type assertions (as) used - needs proper typing"},"category":"security"},
    "typescript":           {"tier":"pre-commit","gates":["check-fast","check","check-all"],"autofix":"none","cmmi":1,"filetypes":["ts"],"skip":{"enabled":false},"category":"code"},
    "filesize":             {"tier":"pre-push","gates":["check","check-all"],"autofix":"none","cmmi":2,"filetypes":["*"],"skip":{"enabled":true,"reason":"Files need splitting","files":["src/providers/google/index.ts","src/cli.ts"]},"category":"structure"},
    "complexity":           {"tier":"pre-push","gates":["check","check-all"],"autofix":"none","cmmi":2,"filetypes":["ts"],"skip":{"enabled":false},"category":"code"},
    "comments":             {"tier":"pre-push","gates":["check","check-all"],"autofix":"none","cmmi":2,"filetypes":["ts"],"skip":{"enabled":true,"reason":"Comment ratio below 20% - needs documentation pass"},"category":"code"},
    "deps":                 {"tier":"pre-push","gates":["check","check-all"],"autofix":"none","cmmi":2,"filetypes":["json"],"skip":{"enabled":false},"category":"structure"},
    "interface-segregation": {"tier":"pre-push","gates":["check","check-all"],"autofix":"none","cmmi":2,"filetypes":["ts"],"skip":{"enabled":true,"reason":"Interfaces need splitting"},"category":"structure"},
    "types-colocation":     {"tier":"pre-push","gates":["check","check-all"],"autofix":"none","cmmi":2,"filetypes":["ts"],"skip":{"enabled":true,"reason":"Centralized types file - needs refactor to colocate"},"category":"structure"},
    "import-paths":         {"tier":"pre-push","gates":["check","check-all"],"autofix":"partial","cmmi":2,"filetypes":["ts"],"skip":{"enabled":false},"category":"code"},
    "coverage":             {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":2,"filetypes":["ts"],"skip":{"enabled":false},"category":"quality"},
    "traceability":         {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["sh"],"skip":{"enabled":true,"reason":"Scripts missing ADR references"},"category":"quality"},
    "language":             {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["md"],"skip":{"enabled":true,"reason":"Dutch words in docs - needs translation"},"category":"quality"},
    "emoji":                {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["ts"],"skip":{"enabled":false},"category":"quality"},
    "async":                {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["ts"],"skip":{"enabled":true,"reason":".then() usage - needs async/await refactor"},"category":"quality"},
    "docs":                 {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["md"],"skip":{"enabled":false},"category":"quality"},
    "colors":               {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["ts"],"skip":{"enabled":false},"category":"quality"},
    "search":               {"tier":"ci","gates":["check-all"],"autofix":"none","cmmi":3,"filetypes":["sh"],"skip":{"enabled":true,"reason":"Scripts use grep -r instead of lib/search.sh"},"category":"quality"}
  }
}
```

### 2. Maturity Score Script

`scripts/maturity-score.sh` — reads registry, calculates score:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Calculates CMMI maturity score from checks-registry.json
# Score = active checks weighted by CMMI level

REGISTRY=".config/checks-registry.json"
declare -A WEIGHTS=([0]=1 [1]=2 [2]=3 [3]=4)
declare -A TOTALS=([0]=0 [1]=0 [2]=0 [3]=0)
declare -A ACTIVE=([0]=0 [1]=0 [2]=0 [3]=0)

while IFS= read -r line; do
  cmmi=$(echo "$line" | jq -r '.cmmi')
  skipped=$(echo "$line" | jq -r '.skip.enabled')
  TOTALS[$cmmi]=$(( ${TOTALS[$cmmi]} + 1 ))
  [[ "$skipped" != "true" ]] && ACTIVE[$cmmi]=$(( ${ACTIVE[$cmmi]} + 1 ))
done < <(jq -c '.checks[]' "$REGISTRY")

score=0; max=0
for level in 0 1 2 3; do
  w=${WEIGHTS[$level]}
  t=${TOTALS[$level]}
  a=${ACTIVE[$level]}
  level_score=$(( a * w ))
  level_max=$(( t * w ))
  score=$(( score + level_score ))
  max=$(( max + level_max ))
  pct=$(( t > 0 ? (a * 100 / t) : 0 ))
  printf "  CMMI %d: %d/%d active (%d%%) × weight %d = %d/%d\n" \
    "$level" "$a" "$t" "$pct" "$w" "$level_score" "$level_max"
done

total_pct=$(( max > 0 ? (score * 100 / max) : 0 ))
printf "\n  Total: %d/%d (%d%%)\n" "$score" "$max" "$total_pct"

# Determine effective level
if (( ${ACTIVE[0]} == ${TOTALS[0]} && ${ACTIVE[1]} == ${TOTALS[1]} )); then
  if (( ${ACTIVE[2]} == ${TOTALS[2]} )); then
    echo "  Level: CMMI 3 (Optimizing) ★★★"
  else
    echo "  Level: CMMI 2 (Defined) ★★☆"
  fi
elif (( ${ACTIVE[0]} == ${TOTALS[0]} )); then
  echo "  Level: CMMI 1 (Managed) ★☆☆"
else
  echo "  Level: CMMI 0 (Initial) ☆☆☆"
fi
```

### 3. Unified Runner

Pre-commit, pre-push, and Makefile targets all read from the same registry:

```bash
# In pre-commit.sh:
CHECKS=$(jq -r '.checks | to_entries[] | select(.value.tier == "pre-commit") | .key' "$REGISTRY")

# In pre-push.sh:
CHECKS=$(jq -r '.checks | to_entries[] | select(.value.tier == "pre-commit" or .value.tier == "pre-push") | .key' "$REGISTRY")

# In make check-all:
CHECKS=$(jq -r '.checks | keys[]' "$REGISTRY")
```

### 4. Consistency Validation

`scripts/checks/quality/registry-integrity.sh` — ensures no drift:

```bash
check_registry_integrity() {
  local registry=".config/checks-registry.json"
  local errors=0
  
  # Every check in registry must have a script
  while IFS= read -r name; do
    found=0
    for f in scripts/checks/*/*.sh; do
      grep -q "^check_${name//-/_}()" "$f" && found=1 && break
    done
    [[ $found -eq 0 ]] && { echo "MISSING: check_${name//-/_}() not found"; errors=$((errors+1)); }
  done < <(jq -r '.checks | keys[]' "$registry")
  
  # Every check script must be in registry
  for f in scripts/checks/*/*.sh; do
    grep -oP '^check_\K[a-z_]+' "$f" | while read -r func; do
      name="${func//_/-}"
      jq -e ".checks[\"$name\"]" "$registry" >/dev/null 2>&1 || \
        { echo "UNREGISTERED: $name in $f"; errors=$((errors+1)); }
    done
  done
  
  return $errors
}
```

## CMMI Process Area Mapping (from v1.3 spreadsheet)

| Our Check | CMMI PA | Goal |
|-----------|---------|------|
| gitleaks, pii, no-hardcoded-secrets | CM - Establish Integrity | Prevent unauthorized changes |
| typescript | VER - Verify Selected Work Products | Type correctness |
| coverage | VER - Prepare for Verification | Test adequacy |
| traceability | REQM - Maintain Bidirectional Traceability | Requirements → code → test |
| interface-segregation | TS - Develop the Design | Clean architecture |
| complexity | MA - Provide Measurement Results | Measurable quality |
| comments | PPQA - Provide Objective Insight | Self-documenting code |
| docs | OPD - Establish Organizational Process Assets | Knowledge management |

## Consequences

**Positive:**
- Single file governs all check behavior
- Maturity score gives instant project health view
- Consistency validation prevents drift
- CMMI mapping justifies each check's existence
- Skip tracking with expiry dates creates accountability

**Negative:**
- Migration from 2 files to 1 registry
- jq dependency for all runners
- CMMI mapping is interpretive (not auditable certification)

## Related

- [ADR-020: Shift-Left Fail-Fast Checks](020-shift-left-fail-fast-checks.md)
- [ADR-019: Quality Check Skip Configuration](019-quality-check-skip-configuration.md)
- [ADR-014: Git Workflow Quality Gates](014-git-workflow-quality-gates.md)
- llama-cli ADR-048: Lean Quality Framework
- CMMI-DEV v1.3 (~/Documents/cmmi-checklist-v1.3.xls)
