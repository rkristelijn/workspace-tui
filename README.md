# workspace-tui

Terminal User Interface for workspace management — Google, Microsoft, Proton, Apple.

## What

CLI tool to read your calendar, email, and tasks from the terminal. Works over SSH.

## Install

```bash
make install
```

## Use

```bash
pnpm cli <command> [options]

Commands:
  calendars   List all calendars
  calendar    List calendar events
  emails      List emails
  tasks       List tasks
  lists       List task lists

Options:
  --mode ai|human       Output format
  --limit N             Max items
  --calendar-ids IDS    Filter by calendar
  --search TEXT         Search query
  --help                Show help
```

## Examples

```bash
pnpm cli calendar --mode=human          # Agenda aankomende week
pnpm cli calendars                      # Alle agenda's
pnpm cli emails --has-attachment        # Emails met bijlagen
pnpm cli tasks --list-ids="Jady"        # Taken van Jady
pnpm cli lists                          # Alle takenlijsten
```

## Docs

- [CLI Usage](docs/cli-usage.md) — Complete CLI reference
- [AI Integration](docs/ai-integration.md) — How AI agents use this tool
- [Architecture](docs/target-architecture.md) — System design
- [ADRs](docs/adr/) — Architectural decisions