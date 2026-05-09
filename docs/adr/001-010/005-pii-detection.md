# ADR-005: PII Detection Patterns

*Status*: Accepted · *Date*: 2026-05-08

## Context

Personally Identifiable Information (PII) can accidentally leak into code through:
- Hardcoded credentials in examples
- Test data with real information
- Debug logs with sensitive data
- Documentation with real names/emails
- Comments with internal hostnames

According to NIST and GDPR definitions, PII includes both direct identifiers (SSN, credit cards) and indirect identifiers (IP addresses, device IDs) that could identify individuals.

## Decision

Implement pre-commit PII detection using `.config/.pii` pattern file covering:

**Linked Information (Direct Identifiers):**
- Social Security Numbers
- Credit card numbers
- Passport numbers
- Driver's licenses

**Linkable Information (Indirect Identifiers):**
- IP addresses (full, not masked)
- MAC addresses

**Sensitive PII:**
- Bank account numbers
- IBAN numbers
- API keys (OpenAI, GitHub, AWS, Google)
- Medical record numbers

**Personal Context:**
- Hostnames
- Personal names
- Phone numbers
- Email addresses (specific domains)

## Implementation

`.config/.pii` contains regex patterns (one per line).
`.config/check-pii.sh` scans staged files before commit.

Developers customize `.config/.pii` with their own patterns (file is gitignored).

## Consequences

**Positive:**
- Prevents accidental PII commits
- Fast (grep-based, <100ms)
- Customizable per developer
- Catches common mistakes early

**Negative:**
- False positives possible (e.g., example credit card numbers)
- Requires developer to maintain their own patterns
- Regex-based (not semantic analysis)

**Fallback:**
Use `git commit --no-verify` to bypass check if false positive occurs, but document why in commit message.

## References

- [NIST Guide to Protecting PII](https://csrc.nist.gov/publications/detail/sp/800-122/final)
- [GDPR Article 4(1) - Personal Data](https://gdpr-info.eu/art-4-gdpr/)
- [Piwik PRO: What is PII](https://piwik.pro/blog/what-is-pii-personal-data/)

## Enforcement

- `scripts/checks/pii.sh`
