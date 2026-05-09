# ADR-016: TypeScript Path Aliases

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 4 - Implementation

## Context

Deep relative imports (`../../../data/types`) create spaghetti code and break when files move. TypeScript supports path aliases for cleaner imports.

## Decision

Use TypeScript path aliases for all cross-directory imports:

```typescript
❌ Bad:  import { Email } from '../../../data/types.js'
✅ Good: import { Email } from '@/data/types.js'
```

### Configuration

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["../src/*"],
      "@data/*": ["../src/data/*"],
      "@providers/*": ["../src/providers/*"],
      "@tui/*": ["../src/tui/*"],
      "@utils/*": ["../src/utils/*"]
    }
  }
}
```

### Rules

1. **Use `@/` for src root** - `@/data/types`
2. **Use specific aliases** - `@data/types`, `@providers/google`
3. **Relative OK within same dir** - `./helper` is fine
4. **Never `../../..`** - Max one level up

## Consequences

**Positive:**
- Refactoring-safe (move files freely)
- Clear import hierarchy
- No spaghetti imports
- Better IDE autocomplete

**Negative:**
- Requires tsconfig setup
- Build tools must support aliases
- Slightly more config

## Implementation

Check script validates no deep relative imports:

```bash
# Detect ../../.. imports
grep -r "\.\./\.\./\.\." src/ --include="*.ts"
```

## Related

- [ADR-005: Interface Segregation](../001-010/005-interface-segregation.md)
- [ADR-009: Script Separation of Concerns](../001-010/009-script-separation-of-concerns.md)
