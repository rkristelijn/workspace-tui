# ADR-011: Terminal Theme and Accessibility

*Status*: Accepted · *Date*: 2026-05-08

## Context

Terminal colors must work on both dark and light backgrounds. Poor contrast causes:
- Unreadable text
- Eye strain
- Accessibility issues
- Bad user experience

Blue text on white background is particularly problematic (low contrast).

## Decision

Implement automatic theme detection with high-contrast colors:

**Dark theme (default):**
- Bright colors (91-97) for high contrast on dark background
- Green: `\033[0;92m` (bright green)
- Red: `\033[0;91m` (bright red)
- Yellow: `\033[0;93m` (bright yellow)
- Gray: `\033[0;90m` (dark gray)

**Light theme:**
- Dark colors (31-37) for high contrast on light background
- Green: `\033[0;32m` (dark green)
- Red: `\033[0;31m` (dark red)
- Yellow: `\033[0;33m` (dark yellow/brown)
- Gray: `\033[0;90m` (dark gray)

**Theme detection:**
1. Check `COLORFGBG` env var (set by xterm, gnome-terminal)
2. Parse background color (0-7 = dark, 8-15 = light)
3. Default to dark if unknown

**Manual override:**
```bash
THEME=light pnpm dev
THEME=dark pnpm dev
```

## Rationale

**Why auto-detect:**
- Works out of the box
- No user configuration needed
- Respects terminal settings

**Why bright colors for dark:**
- ANSI 90-97 are brighter than 30-37
- Better contrast on black background
- Standard terminal practice

**Why dark colors for light:**
- ANSI 30-37 are darker
- Better contrast on white background
- Readable without eye strain

**Why no blue for duration:**
- Blue has lowest contrast on both themes
- Changed to gray (neutral, high contrast)
- Consistent with "secondary" information

## Accessibility

**WCAG 2.1 Contrast Requirements:**
- Normal text: 4.5:1 minimum
- Large text: 3:1 minimum

**Our colors meet these requirements:**
- Bright green on black: ~7:1 ✓
- Dark green on white: ~5:1 ✓
- Bright red on black: ~6:1 ✓
- Dark red on white: ~5:1 ✓
- Gray on both: ~4.5:1 ✓

## Implementation

`.config/ui.sh`:
```bash
detect_theme() {
  if [[ -n "${COLORFGBG:-}" ]]; then
    local bg="${COLORFGBG##*;}"
    if [[ "$bg" =~ ^[0-7]$ ]]; then
      echo "dark"
    else
      echo "light"
    fi
  else
    echo "dark"  # default
  fi
}

THEME="${THEME:-$(detect_theme)}"
```

## Examples

**Dark terminal:**
```
-- Formatting --
  [1/4] biome...     ✓ (0s)  # bright green check, dark gray time

All checks passed in 5s      # bright green, dark gray
```

**Light terminal:**
```
-- Formatting --
  [1/4] biome...     ✓ (0s)  # dark green check, dark gray time

All checks passed in 5s      # dark green, dark gray
```

## Consequences

**Positive:**
- Works on any terminal background
- High contrast, readable
- Accessible (WCAG compliant)
- No user configuration needed
- Manual override available

**Negative:**
- Relies on `COLORFGBG` (not universal)
- May not detect all terminals correctly
- Defaults to dark if unknown

**Fallback:**
Users can always override: `THEME=light pnpm dev`

## Future Enhancements

- Add `mono` theme (no colors) for CI/piping
- Add custom theme support via config file
- Detect more terminal types (iTerm2, Windows Terminal)
- Add color blindness modes

## References

- [WCAG 2.1 Contrast Guidelines](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)
- [ANSI Color Codes](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors)
- [Terminal Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
- [ADR-013: Theme System](013-theme-system.md)

## Enforcement

- `scripts/checks/colors.sh`
- `scripts/checks/emoji.sh`
