# ADR-007: English-Only with Active Voice

*Status*: Accepted · *Date*: 2026-05-08

## Context

Open source projects need consistent language and writing style for:
- Code (variables, functions, comments)
- Documentation (README, ADRs, guides)
- Commit messages

Mixed languages and passive voice create:
- Barriers for international contributors
- Unclear decision documentation
- Weak, indirect communication

## Decision

**All code and documentation must be in English with active/declarative voice.**

**Language:**
- English only (no Dutch, German, etc.)
- Applies to: code, docs, commits, comments

**Writing Style (ADRs):**
- ✅ Active/Declarative: "Use config.json for credentials"
- ❌ Passive: "Config.json is used for credentials"
- ✅ Direct: "Store credentials in ~/.workspace-tui/"
- ❌ Indirect: "Credentials will be stored in ~/.workspace-tui/"

**Examples:**

| Passive (avoid) | Active (prefer) |
|-----------------|-----------------|
| "OAuth is used for authentication" | "Use OAuth for authentication" |
| "Credentials are stored in config.json" | "Store credentials in config.json" |
| "The provider will be initialized" | "Initialize the provider" |
| "Data can be cached" | "Cache data" |

## Rationale

**Why English:**
- International standard
- Largest contributor pool
- Better tooling support

**Why Active Voice:**
- Clearer decisions
- Stronger documentation
- Easier to understand
- Follows technical writing best practices

## Enforcement

`.config/check-language.sh` checks for:
- Common Dutch words
- Passive voice patterns in ADRs

Runs in pre-commit hook.

## Exceptions

**Allowed:**
- User-facing i18n content (future)
- Test data with non-English strings
- Quotes from external sources

**Passive voice OK in:**
- Background/context sections (describing existing state)
- Consequences (describing effects)

## Implementation

Pre-commit checks:
```bash
# Dutch words
grep -r "bijvoorbeeld\|namelijk\|waarom" src/ docs/

# Passive voice in ADRs
grep -r "will be\|is used\|are used" docs/adr/
```

## Consequences

**Positive:**
- Clear, direct documentation
- Consistent writing style
- Professional appearance
- Easier for non-native speakers

**Negative:**
- Requires discipline
- May slow down Dutch developers
- False positives possible

## References

- [Google Developer Documentation Style Guide](https://developers.google.com/style/voice) - Use active voice
- [Microsoft Writing Style Guide](https://learn.microsoft.com/en-us/style-guide/grammar/verbs#use-active-voice) - Prefer active voice
- [Plain Language Guidelines](https://www.plainlanguage.gov/guidelines/conversational/use-active-voice/) - Use active voice

## Enforcement

- `scripts/checks/language.sh`
