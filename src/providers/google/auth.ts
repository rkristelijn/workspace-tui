import { createServer } from 'node:http';
import { google } from 'googleapis';

type Credentials = {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
};

const SCOPES = [
  'https://www.googleapis.com/auth/calendar.readonly',
  'https://www.googleapis.com/auth/gmail.readonly',
  'https://www.googleapis.com/auth/tasks.readonly',
];

export async function authenticate(clientId: string, clientSecret: string): Promise<Credentials> {
  const oauth2Client = new google.auth.OAuth2(
    clientId,
    clientSecret,
    'http://localhost:3000/oauth2callback'
  );

  const authUrl = oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: SCOPES,
  });

  console.log('Open:', authUrl);

  const code = await getAuthCode();
  const { tokens } = await oauth2Client.getToken(code);

  return {
    clientId,
    clientSecret,
    refreshToken: tokens.refresh_token || '',
  };
}

function getAuthCode(): Promise<string> {
  return new Promise((resolve, reject) => {
    const server = createServer((req, res) => {
      if (req.url?.startsWith('/oauth2callback')) {
        const url = new URL(req.url, 'http://localhost:3000');
        const code = url.searchParams.get('code');
        if (!code) {
          res.writeHead(400);
          res.end('Missing auth code');
          server.close();
          reject(new Error('Missing auth code'));
          return;
        }

        res.writeHead(200, { 'Content-Type': 'text/html' });
        res.end('<h1>Authenticated!</h1>');

        server.close();
        resolve(code);
      }
    });

    server.listen(3000);

    server.on('error', reject);
  });
}
