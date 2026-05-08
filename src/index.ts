/**
 * Entry point for workspace-tui
 * Orchestrates auth and display — each concern in its own function.
 */

import 'dotenv/config';

import { loadConfig, saveConfig } from './config.js';
import type { Provider } from './providers/base.js';
import { authenticate } from './providers/google/auth.js';
import { GoogleProvider } from './providers/google/index.js';

/** Google credentials shape */
type GoogleCredentials = {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
};

/** Get Google credentials — from config or via OAuth flow */
async function getCredentials(): Promise<GoogleCredentials> {
  const config = loadConfig();

  if (config.providers.google) return config.providers.google;

  console.log('No Google credentials found. Starting OAuth flow...\n');

  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    console.error('ERROR: Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET environment variables');
    console.error('See docs/google-oauth-setup.md for instructions');
    process.exit(1);
  }

  const credentials = await authenticate(clientId, clientSecret);
  config.providers.google = credentials;
  saveConfig(config);
  console.log('\nCredentials saved to ~/.workspace-tui/config.json\n');
  return credentials;
}

/** Show today's calendar events */
async function showCalendar(provider: Provider) {
  if (!provider.calendar) return;
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  console.log('Calendar events:');
  const events = await provider.calendar.getEvents(today, tomorrow);
  for (const e of events) {
    console.log(`  - ${e.title} (${e.start.toLocaleTimeString()})`);
  }
}

/** Show recent emails */
async function showEmails(provider: Provider) {
  if (!provider.email) return;
  console.log('\nRecent emails:');
  const emails = await provider.email.getEmails(5);
  for (const e of emails) {
    console.log(`  - ${e.subject} from ${e.from}`);
  }
}

/** Show all tasks */
async function showTasks(provider: Provider) {
  if (!provider.tasks) return;
  console.log('\nTasks:');
  const tasks = await provider.tasks.getTasks();
  for (const t of tasks) {
    console.log(`  - [${t.done ? 'x' : ' '}] ${t.title}`);
  }
}

async function main() {
  const credentials = await getCredentials();
  const provider = new GoogleProvider(credentials);
  console.log('workspace-tui\n');
  await showCalendar(provider);
  await showEmails(provider);
  await showTasks(provider);
}

main().catch(console.error);
