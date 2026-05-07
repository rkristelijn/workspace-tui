# workspace-tui

Terminal User Interface for workspace management — Google, Microsoft, Proton, Apple.

## What it does

- **Read** — calendar, email, tasks in your terminal
- **Plan** — day/week/month/year with Covey-style workflows
- **Write** — draft emails and tasks with AI assistance
- **Manage** — tasks across providers from one interface
- **Remote-friendly** — works over SSH, no GUI required

## Providers

| Provider | Calendar | Email | Tasks | Status |
|----------|----------|-------|-------|--------|
| Google Workspace | ✅ | ✅ | ✅ | Planned |
| Microsoft 365 | ✅ | ✅ | ✅ | Planned |
| Proton | ✅ | ✅ | — | Future |
| Apple iCloud | ✅ | — | ✅ | Future |

## Documentation

- [ADR-001: Vision](adr/001-vision.md)
- [ADR-002: BDD + TDD](adr/002-bdd-tdd.md)
- [ADR-003: Quality-Driven Development](adr/003-quality-driven-development.md)
- [General TUI Design](docs/general-tui-design.md)
- [Target Architecture](docs/target-architecture.md)

## Development

```bash
npm install
npm run dev       # start TUI
npm test          # unit + integration tests
npm run test:e2e  # BDD/Cucumber tests
npm run check     # all quality gates
```

## Status

🚧 Early design phase — ADRs and architecture docs in progress.
