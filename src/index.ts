/**
 * Entry point for workspace-tui
 * Handles OAuth flow and displays calendar, email, and tasks from Google Workspace
 */

import { loadConfig, saveConfig } from './config.js';
import { authenticate } from './providers/google/auth.js';
import { GoogleProvider } from './providers/google/index.js';

/**
 * Main application entry point
 * - Checks for existing credentials
 * - Runs OAuth flow if needed
 * - Displays calendar events, emails, and tasks
 */
async function main() {
  const config = loadConfig();

  // Run OAuth flow if no credentials exist
  if (!config.providers.google) {
    console.log('No Google credentials found. Starting OAuth flow...\n');

    const clientId = process.env.GOOGLE_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      console.error('ERROR: Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET environment variables');
      console.error('See docs/google-oauth-setup.md for instructions');
      process.exit(1);
    }

    // Authenticate and save credentials
    const credentials = await authenticate(clientId, clientSecret);
    config.providers.google = credentials;
    saveConfig(config);
    console.log('\nCredentials saved to ~/.workspace-tui/config.json\n');
  }

  // Initialize provider with saved credentials
  const provider = new GoogleProvider(config.providers.google);

  console.log('workspace-tui\n');

  // Get today's date range for calendar events
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  // Display calendar events for today
  if (provider.calendar) {
    console.log('Calendar events:');
    const events = await provider.calendar.getEvents(today, tomorrow);
    for (const e of events) {
      console.log(`  - ${e.title} (${e.start.toLocaleTimeString()})`);
    }
  }

  // Display 5 most recent emails
  if (provider.email) {
    console.log('\nRecent emails:');
    const emails = await provider.email.getEmails(5);
    for (const e of emails) {
      console.log(`  - ${e.subject} from ${e.from}`);
    }
  }

  // Display all tasks
  if (provider.tasks) {
    console.log('\nTasks:');
    const tasks = await provider.tasks.getTasks();
    for (const t of tasks) {
      console.log(`  - [${t.done ? 'x' : ' '}] ${t.title}`);
    }
  }
}

// Run main and handle errors
main().catch(console.error);
