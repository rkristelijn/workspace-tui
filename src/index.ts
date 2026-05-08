/**
 * Entry point for workspace-tui
 * Orchestrates auth and display — each concern in its own function.
 */

import 'dotenv/config';

import { loadConfig, saveConfig } from './config.js';
import { authenticate } from './providers/google/auth.js';
import { GoogleProvider } from './providers/google/index.js';
import { TuiApp } from './tui/app.js';

type GoogleCredentials = {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
};

async function getCredentials(): Promise<GoogleCredentials> {
  const config = loadConfig();

  if (config.providers.google) return config.providers.google;

  // TODO: prefer spread operator below
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    // TODO: need better instructions and link to documentation
    console.error('Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env');
    process.exit(1);
  }

  const credentials = await authenticate(clientId, clientSecret);
  config.providers.google = credentials;
  saveConfig(config);
  return credentials;
}

async function main() {
  const credentials = await getCredentials();
  new GoogleProvider(credentials); // TODO: pass to TuiApp

  const app = new TuiApp();
  await app.run();
}

main().catch(console.error);
