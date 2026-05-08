# workspace-tui

Terminal User Interface for workspace management — Google, Microsoft, Proton, Apple.

## Status

Early development - MVP focus: read-only Calendar, Email, Tasks from Google Workspace.

## What it does

- **Read** — calendar, email, tasks in your terminal
- **Plan** — day/week/month/year with Covey-style workflows
- **Write** — draft emails and tasks with AI assistance
- **Manage** — tasks across providers from one interface
- **Remote-friendly** — works over SSH, no GUI required

## Providers

| Provider | Calendar | Email | Tasks | Status |
|----------|----------|-------|-------|--------|
| Google Workspace | WIP | WIP | WIP | MVP |
| Microsoft 365 | - | - | - | Planned |
| Proton | - | - | - | Future |
| Apple iCloud | - | - | - | Future |

## Quick Start

```bash
make install
make dev
```

## Documentation

- [ADR-001: Vision](docs/adr/001-vision.md)
- [ADR-002: BDD + TDD](docs/adr/002-bdd-tdd.md)
- [ADR-003: Quality-Driven Development](docs/adr/003-quality-driven-development.md)
- [ADR-004: Clean Root Config](docs/adr/004-clean-root-config.md)
- [ADR-005: Interface Segregation](docs/adr/005-interface-segregation.md)
- [ADR-006: EditorConfig + Biome](docs/adr/006-editorconfig-biome.md)
- [General TUI Design](docs/general-tui-design.md)
- [Target Architecture](docs/target-architecture.md)

## Development

```bash
pnpm install      # install dependencies
pnpm dev          # start TUI
pnpm test         # unit + integration tests
pnpm test:e2e     # BDD/Cucumber tests
pnpm check        # all quality gates
```

Or use Makefile shortcuts:

```bash
make install
make dev
make check
```
