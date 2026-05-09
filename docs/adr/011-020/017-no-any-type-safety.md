# ADR-017: No Any - Type Safety First

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 4 - Implementation

## Context

TypeScript's `any` type disables all type checking. Using `any` defeats the purpose of TypeScript and creates runtime bugs that the compiler could catch.

## Decision

**Ban `any` completely. Use `unknown` when type is truly unknown.**

### Rules

1. **Never use `any`** - Biome error, not warning
2. **Use `unknown` for truly unknown types** - Then narrow with type guards
3. **Use generics** - `<T>` instead of `any`
4. **Type external APIs** - Create interfaces for third-party responses
5. **Use type assertions sparingly** - Only when you've validated the type

### Examples

```typescript
❌ Bad:  function sort(items: any[]) { ... }
✅ Good: function sort<T>(items: T[], compare: (a: T, b: T) => number) { ... }

❌ Bad:  const data: any = await fetch(url)
✅ Good: const data: unknown = await fetch(url)
         if (isValidResponse(data)) { /* now typed */ }

❌ Bad:  headers.find((h: any) => h.name === 'From')
✅ Good: interface Header { name: string; value: string }
         headers.find((h: Header) => h.name === 'From')

❌ Bad:  function handle(error: any) { ... }
✅ Good: function handle(error: unknown) {
           if (error instanceof Error) { /* typed */ }
         }
```

### Why `unknown` over `any`

- `unknown` forces type checking before use
- `any` silently allows anything (runtime bombs)
- `unknown` is type-safe, `any` is not

## Consequences

**Positive:**
- Catch bugs at compile time
- Better IDE autocomplete
- Self-documenting code
- Refactoring safety

**Negative:**
- More upfront typing work
- Requires type guards for `unknown`
- External APIs need interface definitions

## Implementation

```json
// biome.json
{
  "suspicious": {
    "noExplicitAny": "error"  // Not "warn"
  }
}
```

## Migration

Existing `any` usage must be replaced with:
1. Proper types (interfaces/generics)
2. `unknown` + type guards
3. Type assertions (only after validation)

## Related

- [ADR-016: TypeScript Path Aliases](016-typescript-path-aliases.md)
- [ADR-007: English Active Voice](../001-010/007-english-active-voice.md)
