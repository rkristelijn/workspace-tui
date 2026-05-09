# ADR-018: Explicit Null Handling

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 4 - Implementation

## Context

JavaScript has `null`, `undefined`, and optional properties. Implicit conversions (`!!value`, `value || default`) hide bugs. TypeScript's strict mode catches these, but we need conventions.

## Decision

**Be explicit about null/undefined. Never rely on implicit conversions.**

### Rules

#### 1. Null vs Undefined
```typescript
❌ Bad:  threadId: data.threadId  // Could be null
✅ Good: threadId: data.threadId || undefined  // Explicit: null → undefined
✅ Good: threadId: data.threadId ?? undefined  // Nullish coalescing

// Convention: Use undefined for "not present", avoid null in our types
type Email = {
  threadId?: string;  // undefined, not null
}
```

#### 2. Boolean Checks
```typescript
❌ Bad:  read: !data.labelIds?.includes('UNREAD')  // undefined → true (wrong!)
✅ Good: read: data.labelIds?.includes('UNREAD') === false  // Explicit

❌ Bad:  if (value) { ... }  // 0, '', false all fail
✅ Good: if (value !== undefined) { ... }  // Explicit intent
```

#### 3. Default Values
```typescript
❌ Bad:  const name = data.name || 'Unknown'  // '' becomes 'Unknown'
✅ Good: const name = data.name ?? 'Unknown'  // Only null/undefined
✅ Good: const name = data.name !== undefined ? data.name : 'Unknown'
```

#### 4. Array/Object Defaults
```typescript
❌ Bad:  labels: data.labels || []  // null becomes []
✅ Good: labels: data.labels ?? []  // Explicit nullish check

❌ Bad:  const merged = { ...defaults, ...data }  // Shallow, implicit
✅ Good: const merged = structuredClone({ ...defaults, ...data })  // Deep copy
```

#### 5. Optional Chaining
```typescript
✅ Use:  data?.user?.name  // Safe navigation
❌ Bad:  data && data.user && data.user.name  // Verbose
```

### TypeScript Config

```json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "noUncheckedIndexedAccess": true
  }
}
```

## Rationale

### Why Explicit?

1. **Type Safety**: `null` and `undefined` are different types
2. **Intent**: Code shows what you mean, not what JS does
3. **Bugs**: `!value` treats `0`, `''`, `false` as falsy (often wrong)
4. **Refactoring**: Explicit code survives changes

### Why Prefer `undefined`?

- Optional properties are `undefined` by default
- JSON doesn't have `null` semantics
- Simpler: one "not present" value
- `??` operator handles both anyway

### Why `===` for Booleans?

```typescript
// Implicit (dangerous):
!data.labelIds?.includes('UNREAD')
// If labelIds is undefined → true (wrong!)

// Explicit (safe):
data.labelIds?.includes('UNREAD') === false
// If labelIds is undefined → false (correct!)
```

## Consequences

**Positive:**
- Catches bugs at compile time
- Self-documenting intent
- Refactoring-safe
- No implicit coercion surprises

**Negative:**
- More verbose
- Requires discipline
- Team must understand `??` vs `||`

## Examples

### API Response Handling
```typescript
interface ApiResponse {
  data?: {
    id?: string | null;
    count?: number | null;
  };
}

❌ Bad:
const id = response.data?.id || 'unknown';
const count = response.data?.count || 0;  // null/0 both become 0!

✅ Good:
const id = response.data?.id ?? 'unknown';
const count = response.data?.count ?? 0;  // Only null/undefined → 0
```

### Deep Copy
```typescript
❌ Bad:  const copy = { ...original };  // Shallow
❌ Bad:  const copy = JSON.parse(JSON.stringify(original));  // Loses functions/dates

✅ Good: const copy = structuredClone(original);  // Deep, preserves types
```

## Related

- [ADR-017: No Any - Type Safety First](017-no-any-type-safety.md)
- [ADR-016: TypeScript Path Aliases](016-typescript-path-aliases.md)
