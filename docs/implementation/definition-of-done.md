# Definition of Ready & Definition of Done

**V-Model Layer 5 - Implementation**

## Definition of Ready (DoR)

A task is ready for implementation when:

### Documentation
- [ ] Acceptance criteria defined (see `requirements/acceptance-criteria.md`)
- [ ] Related ADRs documented
- [ ] Dependencies identified and available
- [ ] API contracts defined (if applicable)

### Design
- [ ] Architecture decision made (ADR exists)
- [ ] Interface/API design approved
- [ ] Error handling strategy defined
- [ ] Performance requirements specified

### Environment
- [ ] Development environment setup documented
- [ ] Test data/fixtures available
- [ ] Required credentials/access granted

**Gate:** No implementation starts without DoR checklist complete.

---

## Definition of Done (DoD)

A task is done when:

### Code Quality
- [ ] Code follows ADR-007 (English, active voice)
- [ ] Code follows ADR-004 (EditorConfig + Biome)
- [ ] Code follows ADR-010 (file size < 300 lines, complexity < 10)
- [ ] No hardcoded credentials (ADR-006)
- [ ] PII detection implemented where needed (ADR-005)

### Testing
- [ ] Unit tests written (only if explicitly requested)
- [ ] Manual testing completed
- [ ] Error scenarios tested
- [ ] Edge cases covered

### Documentation
- [ ] Code comments for complex logic
- [ ] README updated if CLI changed
- [ ] ADR updated if decision changed
- [ ] Examples added if new feature

### Integration
- [ ] Builds without errors (`pnpm build`)
- [ ] Linter passes (`pnpm lint`)
- [ ] Type checking passes (`pnpm typecheck`)
- [ ] No console errors in normal operation

### Acceptance
- [ ] All acceptance criteria met
- [ ] Reviewed by at least one other person (if team)
- [ ] Works in target environment (macOS terminal, SSH)

**Gate:** No task is "done" without DoD checklist complete.

---

## Enforcement

These definitions are **mandatory**. The workflow is sacred:

1. **Vision** → Why are we building this?
2. **Requirements** → What does success look like? (DoR)
3. **Architecture** → How will we build it?
4. **Implementation** → Build it (DoD)
5. **Validation** → Does it meet acceptance criteria?

Skip a step = technical debt. Follow the process.
