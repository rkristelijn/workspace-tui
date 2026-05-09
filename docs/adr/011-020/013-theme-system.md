# ADR-013: Theme System

**Status:** Accepted  
**Date:** 2026-05-09  
**Context:** V-Model Layer 4 - Implementation

## Context

Terminal color support varies across environments. Users need customizable themes for accessibility and preference.

## Decision

Implement theme system with:
1. **Default themes** - Light, dark, high-contrast presets
2. **Custom themes** - User-defined color schemes in config
3. **Fallback support** - Graceful degradation for limited color terminals
4. **Semantic colors** - Named colors (primary, warning, error) not hardcoded values

Theme configuration:
```json
{
  "theme": {
    "name": "dark",
    "colors": {
      "primary": "#00ff00",
      "secondary": "#0000ff",
      "warning": "#ffff00",
      "error": "#ff0000",
      "background": "#000000",
      "foreground": "#ffffff"
    }
  }
}
```

## Consequences

**Positive:**
- Accessible to users with visual needs
- Customizable per preference
- Works across terminal types
- Semantic naming enables easy theme switching

**Negative:**
- Adds configuration complexity
- Must test across terminal emulators
- Color rendering varies by environment

## Related

- [ADR-011: Terminal Theme Accessibility](011-020/011-terminal-theme-accessibility.md)
- [ADR-016: TUI Design](/docs/architecture/016-tui-design.md)

## Enforcement

Enforced by: `colors` check in pre-commit/pre-push pipeline.
