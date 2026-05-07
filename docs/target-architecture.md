# Target Architecture

*Status*: Draft · *Date*: 2026-05-07

## Overview

workspace-tui is a TypeScript/Node.js application with a layered architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                        TUI Layer                            │
│                    (blessed / ink)                          │
│   Panels: Calendar | Email | Tasks | AI | Planning          │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Workflow Layer                            │
│         Plan Day | Plan Week | Plan Month | Plan Year       │
│              Covey Quadrants | GTD | Review                 │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      AI Layer                               │
│           Read | Plan | Write | Manage                      │
│         (OpenAI / Ollama / local LLM)                       │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                   Provider Layer                            │
│  Google  │  Microsoft  │  Proton  │  Apple  │  Custom       │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
│         Cache | Config | Auth | Storage                     │
└─────────────────────────────────────────────────────────────┘
```

## Layer details

### TUI Layer — `src/tui/`

Built with `blessed` (Node.js):

```
src/tui/
  app.ts          # Main TUI app, layout manager
  panels/
    calendar.ts   # Calendar panel
    email.ts      # Email panel
    tasks.ts      # Tasks panel
    ai.ts         # AI chat panel
    planning.ts   # Planning panel
  components/
    list.ts       # Reusable list component
    modal.ts      # Modal dialog
    statusbar.ts  # Status bar
    spinner.ts    # Loading spinner
  keybindings.ts  # Global keybinding registry
```

**Why `blessed`:**
- Mature, battle-tested Node.js TUI library
- Full panel/window management
- Mouse + keyboard support
- Works over SSH
- No native dependencies

### Workflow Layer — `src/workflows/`

```
src/workflows/
  plan-day.ts     # Daily planning workflow
  plan-week.ts    # Weekly review + planning
  plan-month.ts   # Monthly review
  plan-year.ts    # Annual review
  covey.ts        # Urgent/important matrix
  gtd.ts          # Getting Things Done capture
```

**Covey quadrants:**

```
              URGENT        NOT URGENT
IMPORTANT  │ Q1: Do now  │ Q2: Schedule  │
           ├─────────────┼───────────────┤
NOT        │ Q3: Delegate│ Q4: Eliminate │
IMPORTANT  │             │               │
```

### AI Layer — `src/ai/`

```
src/ai/
  client.ts       # LLM client (OpenAI / Ollama)
  prompts/
    read.ts       # "What's on my calendar today?"
    plan.ts       # "Schedule focus time for X"
    write.ts      # "Draft email about Y"
    manage.ts     # "Move task Z to next week"
  context.ts      # Build context from provider data
```

### Provider Layer — `src/providers/`

All providers implement `IProvider`:

```typescript
interface IProvider {
  name: string;
  // Calendar
  getEvents(from: Date, to: Date): Promise<CalendarEvent[]>;
  createEvent(event: CalendarEvent): Promise<void>;
  // Email
  getEmails(limit: number): Promise<Email[]>;
  sendEmail(email: Email): Promise<void>;
  // Tasks
  getTasks(): Promise<Task[]>;
  createTask(task: Task): Promise<void>;
  updateTask(id: string, task: Partial<Task>): Promise<void>;
}
```

```
src/providers/
  base.ts         # IProvider interface + base types
  google/
    index.ts      # Google Workspace provider
    auth.ts       # OAuth2 flow
    calendar.ts   # Google Calendar API
    gmail.ts      # Gmail API
    tasks.ts      # Google Tasks API
  microsoft/
    index.ts      # Microsoft 365 provider
    auth.ts       # MSAL OAuth flow
    calendar.ts   # Outlook Calendar API
    mail.ts       # Outlook Mail API
    todo.ts       # Microsoft To Do API
  proton/
    index.ts      # Proton provider (future)
  apple/
    index.ts      # Apple iCloud provider (future)
```

### Data Layer — `src/data/`

```
src/data/
  cache.ts        # In-memory + disk cache with TTL
  config.ts       # Config file (~/.workspace-tui/config.json)
  auth.ts         # Token storage (keychain / encrypted file)
  types.ts        # Shared data types
```

## Data types

```typescript
interface CalendarEvent {
  id: string;
  title: string;
  start: Date;
  end: Date;
  location?: string;
  attendees?: string[];
  provider: string;
}

interface Email {
  id: string;
  from: string;
  to: string[];
  subject: string;
  body: string;
  date: Date;
  read: boolean;
  provider: string;
}

interface Task {
  id: string;
  title: string;
  done: boolean;
  due?: Date;
  priority?: 'high' | 'medium' | 'low';
  quadrant?: 'q1' | 'q2' | 'q3' | 'q4';
  provider: string;
}
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `blessed` | `0.1.81` | TUI framework |
| `googleapis` | `144.0.0` | Google Workspace APIs |
| `@microsoft/microsoft-graph-client` | `3.0.7` | Microsoft 365 APIs |
| `typescript` | `5.4.5` | Language |
| `tsx` | `4.7.2` | TypeScript runner |
| `vitest` | `1.6.0` | Unit testing |
| `@cucumber/cucumber` | `10.8.0` | BDD/E2E testing |

## Directory structure

```
workspace-tui/
  adr/              # Architecture Decision Records
  docs/             # Documentation
  src/
    tui/            # TUI layer
    workflows/      # Workflow layer
    ai/             # AI layer
    providers/      # Provider layer
    data/           # Data layer
    index.ts        # Entry point
  tests/
    unit/           # Unit tests
    integration/    # Integration tests
    e2e/            # E2E/BDD tests (Cucumber)
      features/     # .feature files
      steps/        # Step definitions
  .config/          # Tool configs
  package.json
  tsconfig.json
  README.md
```

## References

- [blessed](https://github.com/chjj/blessed)
- [Google APIs Node.js Client](https://github.com/googleapis/google-api-nodejs-client)
- [Microsoft Graph SDK](https://github.com/microsoftgraph/msgraph-sdk-javascript)
- [Vitest](https://vitest.dev)
- [Cucumber.js](https://cucumber.io/docs/installation/javascript/)
