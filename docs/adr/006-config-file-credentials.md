# ADR-006: Config File for Persistent Credentials

*Status*: Accepted · *Date*: 2026-05-08

## Context

OAuth credentials need to be stored persistently:
- Client ID and Client Secret (for initial setup)
- Refresh Token (for ongoing access without re-authentication)

Options considered:
1. `.env` file in project root
2. `~/.workspace-tui/config.json` in user home directory
3. System keychain (macOS Keychain, Linux Secret Service)

## Decision

Use `~/.workspace-tui/config.json` for persistent OAuth credentials.

**Structure:**
```json
{
  "providers": {
    "google": {
      "clientId": "...",
      "clientSecret": "...",
      "refreshToken": "..."
    }
  }
}
```

**OAuth Flow:**
1. First run: User provides `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` via env vars
2. App opens browser for OAuth consent
3. Refresh token saved to `~/.workspace-tui/config.json`
4. Subsequent runs: App reads from config.json (no env vars needed)

**`.env` usage:**
Reserved for development-only secrets (e.g., AI API keys for testing).

## Rationale

**Why config.json over .env:**
- Persistent across terminal sessions
- No need to set env vars every time
- Supports multiple providers in structured format
- User home directory (not project root) = safer

**Why not system keychain:**
- Adds complexity (platform-specific APIs)
- Overkill for MVP (refresh tokens are already scoped)
- Can migrate later if needed

## Consequences

**Positive:**
- Simple: one JSON file
- Persistent: survives terminal restarts
- Structured: easy to add more providers
- Secure: stored in user home (not project)

**Negative:**
- Plain text storage (not encrypted)
- User must manually delete file to revoke access
- Not synced across machines

**Security:**
- File permissions: `chmod 600 ~/.workspace-tui/config.json` (user-only read/write)
- Refresh tokens are scoped to read-only access
- User can revoke at https://myaccount.google.com/permissions

## Future Improvements

- Encrypt config.json with user password
- Migrate to system keychain for production
- Add `workspace-tui logout` command to delete credentials

## References

- [Google OAuth 2.0 for Desktop Apps](https://developers.google.com/identity/protocols/oauth2/native-app)
- [NIST SP 800-63B: Digital Identity Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

## Enforcement

- `scripts/checks/no-hardcoded-secrets.sh`
- `scripts/checks/gitleaks.sh`
