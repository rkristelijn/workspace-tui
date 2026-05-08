# Google OAuth Setup

## Quick Start

1. **Create Google Cloud Project**
   - Go to https://console.cloud.google.com
   - Create new project: "workspace-tui"

2. **Enable APIs**
   - Google Calendar API
   - Gmail API
   - Google Tasks API

3. **Create OAuth Credentials**
   - Go to "APIs & Services" > "Credentials"
   - Create "OAuth 2.0 Client ID"
   - Application type: "Desktop app"
   - Download credentials JSON

4. **Set Environment Variables**

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-client-secret"
```

5. **Run OAuth Flow**

```bash
pnpm dev
```

This will:
- Open browser for Google authentication
- Save refresh token to `~/.workspace-tui/config.json`
- Start reading your calendar, email, and tasks

## Config File Location

Credentials are stored in: `~/.workspace-tui/config.json`

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

## Security

- Config file is stored in your home directory (not in repo)
- Refresh token allows access without re-authentication
- Revoke access: https://myaccount.google.com/permissions

## Troubleshooting

**"redirect_uri_mismatch" error:**
- Add `http://localhost:3000/oauth2callback` to authorized redirect URIs in Google Cloud Console

**"invalid_grant" error:**
- Delete `~/.workspace-tui/config.json` and re-authenticate

**"insufficient permissions" error:**
- Check that all three APIs are enabled in Google Cloud Console
