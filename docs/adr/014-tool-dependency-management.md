# ADR-014: Tool Dependency Management

*Status*: Accepted · *Date*: 2026-05-08

## Context

Quality checks require external tools (gitleaks, cloc, shellcheck, ripgrep). These tools need:
- Version pinning for reproducibility
- Cross-platform installation (macOS, Linux)
- Clear documentation of what's required vs optional
- Automated setup for new developers

## Decision

Use `package.json` as single source of truth for tool versions:

```json
{
  "tools": {
    "required": {
      "gitleaks": "8.18.0",
      "cloc": "1.90.0"
    },
    "optional": {
      "shellcheck": "0.9.0",
      "ripgrep": "13.0.0"
    }
  }
}
```

**Setup orchestrator:**
- `scripts/setup.sh` - detects platform, delegates to platform script
- `scripts/setup-macos.sh` - installs via Homebrew
- `scripts/setup-linux.sh` - installs via apt + GitHub releases

**Version pinning:**
- No `^` or `~` in package.json
- Exact versions for reproducibility
- Update explicitly when needed

## Rationale

**Why package.json:**
- Already exists, no new file
- Easy to read: `node -p "require('./package.json').tools.required.gitleaks"`
- Familiar format for Node.js developers
- Can be parsed by any language

**Why platform-specific scripts:**
- macOS uses Homebrew
- Linux uses apt (Debian/Ubuntu)
- Different installation methods per tool
- Orchestrator keeps platform detection in one place

**Why exact versions:**
- Reproducible builds
- No surprises from minor/patch updates
- Explicit upgrade decisions
- CI/CD consistency

## Implementation

**Install tools:**
```bash
make install  # Runs pnpm install, which runs scripts/setup.sh
```

**Check tool versions:**
```bash
gitleaks version
cloc --version
shellcheck --version
rg --version
```

**Platform detection:**
```bash
if [[ "$(uname -s)" == "Darwin" ]]; then
  # macOS
elif [[ "$(uname -s)" == "Linux" ]]; then
  # Linux
fi
```

## Consequences

**Positive:**
- Single source of truth (package.json)
- Automated setup for new developers
- Cross-platform support
- Version pinning prevents drift
- Clear required vs optional distinction

**Negative:**
- Requires Homebrew on macOS
- Requires apt on Linux (Debian/Ubuntu only)
- Manual updates needed for version bumps
- Windows not supported (yet)

**Unsupported platforms:**
- Windows - developers must install tools manually
- Linux non-Debian - install tools manually
- Can still use the project, just no automated setup

## Future Enhancements

- Add Windows support (Chocolatey/Scoop)
- Add version checking (warn if installed version differs)
- Add `make update-tools` to upgrade all tools
- Consider Nix for reproducible environments

## References

- [Homebrew](https://brew.sh/)
- [apt](https://wiki.debian.org/Apt)
- llama-cli: `.config/versions.env` + `scripts/dev/setup.sh`

## Enforcement

- `scripts/checks/deps.sh`
- `.npmrc` (engine-strict)
