import { loadConfig, saveConfig } from './config.js';
import { authenticate } from './providers/google/auth.js';
import { GoogleProvider } from './providers/google/index.js';

async function main() {
  const config = loadConfig();

  if (!config.providers.google) {
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
  }

  const provider = new GoogleProvider(config.providers.google);

  console.log('workspace-tui\n');

  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  if (provider.calendar) {
    console.log('Calendar events:');
    const events = await provider.calendar.getEvents(today, tomorrow);
    for (const e of events) {
      console.log(`  - ${e.title} (${e.start.toLocaleTimeString()})`);
    }
  }

  if (provider.email) {
    console.log('\nRecent emails:');
    const emails = await provider.email.getEmails(5);
    for (const e of emails) {
      console.log(`  - ${e.subject} from ${e.from}`);
    }
  }

  if (provider.tasks) {
    console.log('\nTasks:');
    const tasks = await provider.tasks.getTasks();
    for (const t of tasks) {
      console.log(`  - [${t.done ? 'x' : ' '}] ${t.title}`);
    }
  }
}

main().catch(console.error);
