# Tool Denylist

Tools and patterns that don't work reliably in our context (macOS + CI + SSH + pipes).

## Shell Builtins & Commands

| Denied | Problem | Use Instead |
|--------|---------|-------------|
| `python3` in scripts | System dependency, version fragile, not always available | `jq` + `yq` for data transforms, `bash` for logic |
| `stty size` | Fails in non-TTY (CI, pipes, SSH, cron) | `${COLUMNS:-80}` or `tput cols 2>/dev/null \|\| echo 80` |
| `tput` without guard | Garbled output when stdout is not a terminal | `[[ -t 1 ]] && tput setaf 2 \|\| true` |
| `grep -P` | PCRE not available on macOS default grep | `grep -E` (extended regex) |
| `readarray` / `mapfile` | Requires bash 4+; macOS ships bash 3.2 | `while IFS= read -r line; do ... done < <(cmd)` |
| `sed -i ''` | macOS syntax; Linux uses `sed -i` (no quotes) | Write to temp file + `mv` |
| `sed -i` | Linux syntax; macOS requires `sed -i ''` | Write to temp file + `mv` |
| `date +%s%N` | macOS `date` has no nanosecond support | `date +%s` (second precision is fine) |
| `realpath` | Not installed by default on macOS | `cd "$(dirname "$0")" && pwd` |
| `xargs -d '\n'` | GNU-only delimiter flag | `xargs -0` with `find -print0` |
| `find -regex` | Regex syntax differs macOS (BSD) vs Linux (GNU) | `find -name '*.ts' -o -name '*.sh'` |
| `echo -e` | Not POSIX; behavior varies | `printf '%s\n'` |
| `which` | Not POSIX; unreliable on some systems | `command -v` |
| `source` in `/bin/sh` | Bash-only; not POSIX | Use `.` (dot) or ensure `#!/usr/bin/env bash` |

## Network-Dependent Tools

| Denied in Pre-commit | Problem | Move To |
|---------------------|---------|---------|
| `npm audit` | Requires network; slow; flaky | CI only |
| `pnpm audit` | Same as npm audit | CI only |
| `curl`/`wget` checks | Network dependency in hook | CI only |
| License API checks | External service dependency | CI only |

## Heavy/Slow Tools

| Denied in Pre-commit | Problem | Move To |
|---------------------|---------|---------|
| `vitest --coverage` | Runs full test suite (~10s+) | Pre-push or CI |
| `tsc --noEmit` on full project | Slow on large codebases | Only on changed files |
| `npx biome check .` (full scan) | Scans all files, not just staged | `--staged` flag or file list |

## Patterns to Avoid

| Pattern | Problem | Alternative |
|---------|---------|-------------|
| `cat file \| grep` | Useless use of cat | `grep pattern file` |
| `ls \| wc -l` | Breaks on filenames with spaces/newlines | `find . -maxdepth 1 \| wc -l` |
| `for f in $(find ...)` | Word splitting on spaces in paths | `find ... -exec` or `while read` |
| `[[ $? -eq 0 ]]` after command | Redundant; use `if command; then` | `if grep -q pattern file; then` |
| Hardcoded `/tmp` | Insecure; race conditions | `mktemp -d` |
| `cd` without `|| exit` | Silent failure if dir doesn't exist | `cd dir || { echo "fail"; exit 1; }` |
| Global `set -e` with pipes | Masks pipe failures | Add `set -o pipefail` |

## macOS vs Linux Gotchas

| Area | macOS (BSD) | Linux (GNU) | Portable |
|------|-------------|-------------|----------|
| `stat` file size | `stat -f%z file` | `stat -c%s file` | `wc -c < file` |
| `mktemp` | `mktemp -t prefix` | `mktemp --suffix=.tmp` | `mktemp /tmp/prefix.XXXXXX` |
| `sort -V` | Not supported | Version sort | Avoid or check `sort --version-sort` |
| `cp -u` | Not supported | Update only | Check timestamps manually |
| `head -c` | Works | Works | ✓ Portable |

## When to Update This List

Add entries when:
1. A check fails in CI but passes locally (or vice versa)
2. A tool behaves differently on macOS vs Linux
3. A pattern causes issues in non-interactive shells (SSH, pipes)
4. A tool requires network access that shouldn't be in pre-commit

## Related

- [ADR-020: Shift-Left Fail-Fast Checks](/docs/adr/011-020/020-shift-left-fail-fast-checks.md)
- [ADR-012: Tool Dependency Management](/docs/adr/011-020/012-tool-dependency-management.md)
