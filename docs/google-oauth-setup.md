# Google OAuth Setup

## Step 1: Create Google Cloud Project

1. Go to https://console.cloud.google.com
2. Click "Select a project" dropdown (top left)
3. Click "NEW PROJECT"
4. Fill in:
   - Project name: `workspace-tui`
   - Parent resource: `No organisation`
5. Click "CREATE"
6. Wait for project creation, then select it from the dropdown

## Step 2: Enable APIs

1. In your project, go to "APIs & Services" > "Library"
2. Search and enable these APIs (click each, then click "ENABLE"):
   - **Google Calendar API**
   - **Gmail API**
   - **Google Tasks API**

## Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" > "OAuth consent screen"
2. Select "External" user type
3. Click "CREATE"
4. Fill in:
   - App name: `workspace-tui`
   - User support email: your email
   - Developer contact: your email
5. Click "SAVE AND CONTINUE"
6. Click "ADD OR REMOVE SCOPES"
7. Add these scopes:
   - `.../auth/calendar.readonly`
   - `.../auth/gmail.readonly`
   - `.../auth/tasks.readonly`
8. Click "UPDATE" then "SAVE AND CONTINUE"
9. Add your email as test user
10. Click "SAVE AND CONTINUE"

## Step 4: Create OAuth 2.0 Client ID

1. Go to "APIs & Services" > "Credentials"
2. Click "CREATE CREDENTIALS" > "OAuth client ID"
3. Select Application type: "Desktop app"
4. Name: `workspace-tui-desktop`
5. Click "CREATE"
6. Copy the Client ID and Client Secret (or download JSON)

## Step 5: Set Environment Variables

Create `.env` file in project root:

```bash
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
```

Or export directly:

```bash
export GOOGLE_CLIENT_ID="your-client-id.apps.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-client-secret"
```

## Step 6: Run OAuth Flow

```bash
source ~/.nvm/nvm.sh && nvm use 24
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
