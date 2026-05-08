# ADR-004: Clean Root with .config Directory

*Status*: Accepted · *Date*: 2026-05-08

## Context

Project root directories often become cluttered with configuration files for various tools (TypeScript, linters, formatters, test frameworks). This makes it harder to find essential files like README.md, package.json, and source code.

Following the pattern from llama-cli, we want a clean root directory with all tool configurations centralized in `.config/`.

## Decision

Move all tool configuration files to `.config/` directory:

```
workspace-tui/
  .config/
    biome.json          # Biome linter + formatter
    tsconfig.json       # TypeScript compiler
    pre-commit          # Git pre-commit hook
  package.json          # Must stay in root (npm/pnpm requirement)
  .gitignore            # Must stay in root (git requirement)
  README.md
  src/
  docs/
  adr/
```

**Tools that support `.config/`:**
- Biome: `--config-path .config`
- TypeScript: `-p .config/tsconfig.json`
- Custom scripts: can reference `.config/` directly

**Tools that must stay in root:**
- `package.json` - npm/pnpm requirement
- `.gitignore` - git requirement

## Consequences

**Positive:**
- Clean root directory
- Easy to find essential files
- Consistent with llama-cli project structure
- All tool configs in one place

**Negative:**
- Requires explicit paths in package.json scripts
- Some IDEs may need workspace configuration updates
- Relative paths in configs need adjustment (`../src` instead of `./src`)

**Fallback:**
If any tool doesn't work properly with `.config/` location, move that specific config back to root. The goal is cleanliness, not dogma.

## Implementation

Update package.json scripts:
```json
{
  "scripts": {
    "dev": "tsx --tsconfig .config/tsconfig.json src/index.ts",
    "lint": "biome check --config-path .config .",
    "check": "tsc -p .config/tsconfig.json --noEmit"
  }
}
```

Pre-commit hook installed via symlink:
```bash
ln -sf ../../.config/pre-commit .git/hooks/pre-commit
```

## References

- llama-cli project structure
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
