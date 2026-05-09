# ADR-015: Documentation Navigation with READMEs

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 4 - Implementation

## Context

Deep folder structures with relative paths are fragile. Absolute paths don't work in GitHub markdown. We need maintainable navigation.

## Decision

Use README.md files as navigation hubs in each directory.

### Structure

```
docs/
├── README.md              ← Main index
├── adr/
│   ├── README.md          ← ADR index
│   ├── 001-010/
│   │   ├── README.md      ← Decade index
│   │   └── 002-*.md
│   └── 011-020/
│       ├── README.md
│       └── 011-*.md
```

### Rules

1. Every directory has README.md as index
2. Use relative links (GitHub compatible)
3. Navigate through READMEs, not deep links
4. Keep paths short (max 2 levels)

## Consequences

**Positive:**
- Works in GitHub web UI
- Discoverable structure
- Refactoring-safe
- Self-documenting

**Negative:**
- Requires maintaining indexes
- Extra click to reach files

## Related

- [ADR-007: English Active Voice](../001-010/007-english-active-voice.md)

## Enforcement

Enforced by: `docs` check in pre-commit/pre-push pipeline.
