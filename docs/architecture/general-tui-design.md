# General TUI Design Principles

*Based on: [ADR-016: TUI Design](016-tui-design.md), best practices from `htop`, `vim`, `tmux`*

## Core principles

### 1. Keyboard-first

- Every action must be keyboard-accessible
- Mouse support is optional enhancement
- Vim-style navigation where appropriate (`hjkl`, `/` for search)

### 2. Visual hierarchy

Use ANSI 16-color palette (universal terminal support):

| Element | Style | ANSI | Example |
|---------|-------|------|---------|
| Active panel | bold white border | `\033[1m` | Current focus |
| Inactive panel | dim gray border | `\033[2m` | Background panels |
| Selected item | bold green | `\033[1;32m` | Highlighted row |
| Error | bold red | `\033[1;31m` | Error messages |
| Info | cyan | `\033[36m` | Status bar |
| Warning | yellow | `\033[33m` | Alerts |

### 3. Responsive layout

- Adapt to terminal size (min 80x24)
- Panels resize proportionally
- Overflow: scroll, don't truncate
- Status bar always visible

### 4. Consistent keybindings

| Key | Action | Context |
|-----|--------|---------|
| `q` | Quit | Global |
| `?` | Help | Global |
| `Tab` | Next panel | Global |
| `Shift+Tab` | Previous panel | Global |
| `/` | Search | List views |
| `n` / `N` | Next/prev search | List views |
| `j` / `k` | Down/up | List views |
| `g` / `G` | Top/bottom | List views |
| `Enter` | Select/open | List views |
| `Esc` | Cancel/back | Dialogs |

### 5. Feedback

- Loading states: spinner or progress bar
- Errors: modal dialog with clear message
- Success: brief status bar message (2s)
- Async operations: non-blocking with status

### 6. Accessibility

- Respect `NO_COLOR` env var
- `--no-color` CLI flag
- Screen reader friendly (semantic structure)
- High contrast mode option

## Layout patterns

### Panel-based layout

```
┌─────────────────────────────────────────────────┐
│ Calendar (active)                               │
│ ┌─────────────────────────────────────────────┐ │
│ │ Today's events                              │ │
│ │ • 09:00 - 10:00  Team standup               │ │
│ │ • 14:00 - 15:00  1:1 with manager           │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ Tasks                                           │
│ ┌─────────────────────────────────────────────┐ │
│ │ [ ] Review PR #123                          │ │
│ │ [x] Write ADR-001                           │ │
│ └─────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────┤
│ Status: Connected to Google Workspace          │
└─────────────────────────────────────────────────┘
```

### Modal dialogs

```
┌─────────────────────────────────────────────────┐
│                                                 │
│   ┌───────────────────────────────────────┐   │
│   │ Confirm action                        │   │
│   │                                       │   │
│   │ Delete event "Team standup"?          │   │
│   │                                       │   │
│   │ [Y]es  [N]o  [Esc] Cancel            │   │
│   └───────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Best practices

### Performance

- Lazy load data (paginate lists)
- Cache API responses (with TTL)
- Debounce search input
- Virtual scrolling for long lists

### Error handling

- Never crash on API errors
- Show user-friendly error messages
- Retry with exponential backoff
- Offline mode: show cached data

### Testing

- Unit tests: panel rendering logic
- Integration tests: keyboard navigation
- E2E tests: full user flows
- Visual regression tests: screenshots

### Accessibility

- Semantic structure (headings, lists)
- Focus indicators (bold border)
- Keyboard shortcuts documented in help
- Color not the only indicator (use symbols too)

## References

- [no-color.org](https://no-color.org)
- `htop` — process viewer TUI
- `vim` — text editor keybindings
- `tmux` — terminal multiplexer panels
- [ADR-016: TUI Design](016-tui-design.md)
