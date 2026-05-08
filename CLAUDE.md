# CLAUDE.md - AI Agent Guide

This file helps AI agents use workspace-tui correctly.

## Quick Command Reference

```bash
pnpm cli <command> [options]
```

## Commands

| Command | Description |
|---------|-------------|
| `pnpm cli calendars` | List all calendars with IDs |
| `pnpm cli calendar` | List calendar events |
| `pnpm cli emails` | List emails |
| `pnpm cli tasks` | List tasks |
| `pnpm cli lists` | List task lists |

## Calendar IDs (Required for Filtering)

Use exact IDs to filter by calendar:

| Calendar | ID |
|----------|-----|
| Primary | `rkristelijn@gmail.com` |
| Jady | `75ce7bbe0ce80b0241bc51ddbf9fc415fa571e028891489d1effae2d8ef85567@group.calendar.google.com` |
| Zani | `zanicoolen1337@gmail.com` |
| Daily Routine | `vkbpapu2qag0gqs6tpbud6gto4@group.calendar.google.com` |
| Kids on Ice | `97h4lo31ktqhvd5vu2penkqgngp6p0sf@import.calendar.google.com` |

**Find all IDs:** Run `pnpm cli calendars` and use the `id` field.

## Common Patterns

```bash
# Agenda aankomende week
pnpm cli calendar --mode=human --limit=20

# Specifieke agenda
pnpm cli calendar --mode=human --calendar-ids="zanicoolen1337@gmail.com"

# Alle agenda's
pnpm cli calendars

# Takenlijsten
pnpm cli lists

# Taken van specifieke lijst
pnpm cli tasks --list-ids="Jady" --done=false

# Emails met attachments
pnpm cli emails --has-attachment --sort-by=date --limit=10
```

## Output Modes

- `--mode=ai` (default): JSON with schema hints
- `--mode=human`: Compact human-readable

## Filtering

```
--calendar-ids IDS    Calendar ID(s), comma-separated
--list-ids IDS        Task list ID(s), comma-separated
--labels IDS          Email labels (INBOX, SENT, etc.)
--search TEXT         Search query
--read true|false     Read status filter
--starred true|false  Starred status filter
--has-attachment      Emails with attachments only
--done true|false     Task completion filter
--limit N             Max items (default: 20)
--offset N            Pagination offset
--sort-by FIELD       Sort field
--sort-order asc|desc Sort order
```

## AI Mode Output

```json
{
  "meta": {
    "command": "calendar",
    "total": 10,
    "schema": {
      "description": "Array of calendar event objects",
      "parse": "data.map(e => ({ id: e.id, title: e.title, start: e.start, end: e.end }))",
      "fields": "id, calendarId, calendarName, title, description, start, end, location, attendees, color, provider"
    }
  },
  "data": [...]
}
```

**Use `--mode=ai`** (default). The schema tells you available fields and how to parse them.

## Authentication

Credentials are in `~/.workspace-tui/config.json`. No manual auth needed if file exists.

## Read-Only MVP

Only supports reading. No edit/delete operations.