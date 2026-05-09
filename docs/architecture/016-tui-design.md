# ADR-016: TUI Design Principles

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 3 - Architecture

## Context

Terminal UI must be intuitive, accessible, and follow established patterns from tools like htop, vim, and tmux.

## Decision

Design principles:
1. **Keyboard-first navigation** - All actions accessible via keyboard
2. **Visual hierarchy** - Clear sections with borders and spacing
3. **Status indicators** - Always show current state and available actions
4. **Consistent keybindings** - Follow vim/tmux conventions where possible
5. **Responsive layout** - Adapt to terminal size
6. **Color accessibility** - Support theme customization (ADR-013)

Layout structure:
```
┌─ Header (title, filters, search) ─┐
│ Main content area                 │
│ (scrollable list/calendar view)   │
├─ Status bar ──────────────────────┤
└─ Help/shortcuts ──────────────────┘
```

## Consequences

**Positive:**
- Familiar UX for terminal users
- Accessible to screen readers
- Works in any terminal size
- Consistent with Unix philosophy

**Negative:**
- Limited visual richness vs GUI
- Requires learning keybindings
- Terminal color support varies

## Related

- [ADR-013: Theme System](../adr/013-theme-system.md)
- [ADR-011: Terminal Theme Accessibility](../adr/011-terminal-theme-accessibility.md)
- [General TUI Design](../architecture/general-tui-design.md)
