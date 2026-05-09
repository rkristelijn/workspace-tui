# Workflow & Quality Gates

**Process is sacred. This workflow is enforced.**

## V-Model Workflow

```
VISION → REQUIREMENTS → ARCHITECTURE → IMPLEMENTATION → VALIDATION
  ↓          ↓              ↓               ↓              ↓
 Why?      What?          How?           Build          Test
  ↓          ↓              ↓               ↓              ↓
ADR-001   Accept.        ADR-0XX         Code          Verify
         Criteria                        (DoD)         (Accept.)
```

## Phases

### 1. Vision (Why?)
**Location:** `docs/vision/`  
**Output:** ADR-001 or vision document  
**Gate:** Clear problem statement and value proposition

### 2. Requirements (What?)
**Location:** `docs/requirements/`  
**Output:** Acceptance criteria  
**Gate:** Definition of Ready (DoR) complete  
**Checklist:** See `implementation/definition-of-done.md`

### 3. Architecture (How?)
**Location:** `docs/architecture/` + `docs/adr/`  
**Output:** Design docs + ADRs  
**Gate:** Technical approach approved, dependencies clear

### 4. Implementation (Build)
**Location:** `src/`  
**Output:** Working code  
**Gate:** Definition of Done (DoD) complete  
**Checklist:** See `implementation/definition-of-done.md`

### 5. Validation (Test)
**Location:** Tests + manual verification  
**Output:** Verified feature  
**Gate:** All acceptance criteria met

## Quality Gates (Enforced)

### Gate 1: Start Implementation
**Requirement:** DoR complete
- Acceptance criteria defined
- ADRs documented
- Dependencies available

**Action:** If DoR incomplete → STOP, complete requirements first

### Gate 2: Mark as Done
**Requirement:** DoD complete
- Code quality standards met
- Tests pass
- Documentation updated
- Acceptance criteria verified

**Action:** If DoD incomplete → NOT DONE, complete checklist

### Gate 3: Close Task
**Requirement:** Validation complete
- Manual testing done
- Edge cases verified
- Works in target environment

**Action:** If validation fails → REOPEN, fix issues

## Enforcement Mechanisms

1. **Pre-commit hooks** - Lint, format, type check
2. **PR template** - DoD checklist required
3. **Review checklist** - Verify DoR/DoD compliance
4. **Documentation first** - No code without ADR/requirements

## Violations

Skipping steps = technical debt. If you skip:
- Vision → Unclear why feature exists
- Requirements → Unclear what "done" means
- Architecture → Inconsistent implementation
- Implementation → Broken code
- Validation → Bugs in production

**The process exists to prevent these problems. Follow it.**

## Quick Reference

| Phase | Document | Gate |
|-------|----------|------|
| Vision | `vision/001-vision.md` | Problem clear? |
| Requirements | `requirements/acceptance-criteria.md` | DoR complete? |
| Architecture | `architecture/*.md`, `adr/*.md` | Design approved? |
| Implementation | `src/**/*.ts` | DoD complete? |
| Validation | Manual test | Criteria met? |
