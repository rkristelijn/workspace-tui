# ADR-006: EditorConfig + Biome for Multi-Language Formatting

*Status*: Accepted · *Date*: 2026-05-08

## Context

workspace-tui uses multiple file types:
- TypeScript/JavaScript (source code)
- JSON (package.json, tsconfig.json)
- Markdown (README, docs, ADRs)
- YAML (potential configs)
- Shell scripts (pre-commit hooks)

Biome handles JS/TS/JSON but not Markdown, YAML, or shell scripts. Without consistent formatting across all file types, different editors will introduce whitespace inconsistencies.

## Decision

Use **Biome + EditorConfig** together:

**Biome** (`.config/biome.json`):
- TypeScript/JavaScript linting + formatting
- JSON formatting
- Fast, modern, Rust-based

**EditorConfig** (`.editorconfig`):
- Cross-language whitespace rules (charset, line endings, indentation)
- Covers Markdown, YAML, shell scripts
- Editor-agnostic (VSCode, Vim, IntelliJ all support it)

## Configuration

`.editorconfig`:
```ini
[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab

[*.md]
trim_trailing_whitespace = false
```

## Consequences

**Positive:**
- Consistent formatting across all file types
- Editor-agnostic (works in any editor with EditorConfig support)
- Biome handles code-level concerns (linting, imports)
- EditorConfig handles whitespace concerns (universal)
- No overlap conflicts (EditorConfig is whitespace-only)

**Negative:**
- Two config files instead of one
- Minimal overlap for JSON (both tools format it)

**Fallback:**
If conflicts arise, Biome takes precedence for JS/TS/JSON files.

## References

- [EditorConfig](https://editorconfig.org/)
- [Biome](https://biomejs.dev/)
- llama-cli uses same pattern

## Enforcement

- `scripts/checks/editorconfig.sh`
- `biome.json`
