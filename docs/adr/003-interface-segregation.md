# ADR-003: Interface Segregation for Providers

*Status*: Accepted · *Date*: 2026-05-08

## Context

Different workspace providers support different capabilities:
- Google: Calendar + Email + Tasks
- Microsoft: Calendar + Email + Tasks
- Proton: Calendar + Email (no Tasks API)
- Apple: Calendar + Tasks (no Email API via iCloud)

Forcing all providers to implement all methods violates Interface Segregation Principle and creates unnecessary coupling.

## Decision

Split provider interface into separate capabilities:

```typescript
type CalendarProvider = {
  getEvents(from: Date, to: Date): Promise<CalendarEvent[]>;
};

type EmailProvider = {
  getEmails(limit: number): Promise<Email[]>;
};

type TaskProvider = {
  getTasks(): Promise<Task[]>;
};

type Provider = {
  name: string;
  calendar?: CalendarProvider;
  email?: EmailProvider;
  tasks?: TaskProvider;
};
```

**Benefits:**
- Providers only implement what they support
- Easy to add new capabilities without breaking existing providers
- Clear separation of concerns
- Add future CRUD operations per interface

## Examples

```typescript
// Google: full support
const google = new GoogleProvider(creds);
google.calendar.getEvents(from, to);
google.email.getEmails(10);
google.tasks.getTasks();

// Proton: no tasks
const proton = new ProtonProvider(creds);
proton.calendar.getEvents(from, to);
proton.email.getEmails(10);
// proton.tasks is undefined

// Apple: no email
const apple = new AppleProvider(creds);
apple.calendar.getEvents(from, to);
apple.tasks.getTasks();
// apple.email is undefined
```

## Consequences

**Positive:**
- SOLID: Interface Segregation Principle
- Flexible: providers implement only what they support
- Extensible: easy to add new capabilities
- Type-safe: TypeScript enforces optional checks

**Negative:**
- Consumers must check if capability exists before using
- Slightly more verbose than single interface

## Implementation

Each provider implements separate classes for each capability:

```typescript
class GoogleProvider implements Provider {
  name = 'google';
  calendar = new GoogleCalendar(auth);
  email = new GoogleEmail(auth);
  tasks = new GoogleTasks(auth);
}
```

## References

- SOLID Principles: Interface Segregation
- [ADR-001: Vision](../vision/001-vision.md) - multi-provider support

## Enforcement

- `scripts/checks/interface-segregation.sh`
