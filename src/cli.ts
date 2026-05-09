/**
 * CLI orchestrator for workspace-tui.
 * Delegates parsing to cli-parser.ts and formatting to formatters.ts.
 */

import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import {
  type CliOptions,
  type CliResult,
  type Cmd,
  type DataCmd,
  parseArgs,
  parseOptions,
  SCHEMA,
  USAGE,
} from './cli-parser.js';
import { clearVault, loadConfig, saveConfig } from './config.js';
import type { CalendarQuery, DriveQuery, EmailQuery, TaskQuery } from './data/types.js';
import {
  formatCalendar,
  formatCalendars,
  formatDrive,
  formatEmails,
  formatLists,
  formatTasks,
} from './formatters.js';
import { authenticate } from './providers/google/auth.js';
import { GoogleProvider } from './providers/google/index.js';

export { parseArgs, parseOptionalBool, parseOptions } from './cli-parser.js';

/** Main entry point for CLI execution */
async function main() {
  const args = process.argv.slice(2);
  const cmd = parseArgs(args);

  if (cmd === '--help') {
    console.log(USAGE.trim());
    process.exit(0);
  }

  if (cmd === 'logout') {
    console.log(clearVault() ? 'Logged out.' : 'Not logged in.');
    process.exit(0);
  }

  if (cmd === 'download') {
    const fileId = args.find((a) => a.startsWith('--id='))?.split('=')[1];
    const out = args.find((a) => a.startsWith('--out='))?.split('=')[1];
    if (!fileId) {
      console.error('--id=FILE_ID required');
      process.exit(1);
    }
    const config = loadConfig();
    const credentials = await getCredentials(config);
    const provider = new GoogleProvider(credentials);
    const content = await provider.drive.downloadFile(fileId);
    if (!content) {
      console.error('Download returned empty');
      process.exit(1);
    }
    if (out) {
      writeFileSync(out, content);
      console.log(`Saved to ${out}`);
    } else {
      process.stdout.write(content);
    }
    process.exit(0);
  }

  if (!cmd) {
    console.error('Command required');
    console.log(USAGE.trim());
    process.exit(1);
  }

  const { mode, options } = parseOptions(args);
  const config = loadConfig();
  const credentials = await getCredentials(config);

  const provider = new GoogleProvider(credentials);
  const result = await getData(provider, cmd as DataCmd, options);

  if (mode === 'ai') {
    outputAi(cmd as DataCmd, result);
  } else {
    outputHuman(cmd as DataCmd, result);
  }
}

/** Get Google credentials: client ID/secret from .env, refresh token from vault */
async function getCredentials(vault: ReturnType<typeof loadConfig>) {
  const clientId = process.env.GOOGLE_CLIENT_ID;
  const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
  if (!clientId || !clientSecret) {
    console.error('Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env');
    process.exit(1);
  }

  const refreshToken = vault.providers.google?.refreshToken;
  if (refreshToken) {
    return { clientId, clientSecret, refreshToken };
  }

  // No token yet — run OAuth flow
  const credentials = await authenticate(clientId, clientSecret);
  vault.providers.google = credentials;
  saveConfig(vault);
  return credentials;
}

/** Fetch data from provider based on command and options */
async function getData(
  provider: GoogleProvider,
  cmd: DataCmd,
  options: CliOptions
): Promise<CliResult> {
  switch (cmd) {
    case 'calendars':
      return {
        data: await provider.calendar.getCalendars(),
        total: 0,
        limit: 0,
        offset: 0,
        hasMore: false,
      };
    case 'calendar':
      return provider.calendar.getEvents(options as CalendarQuery);
    case 'emails':
      return provider.email.getEmails(options as EmailQuery);
    case 'tasks':
      return provider.tasks.getTasks(options as TaskQuery);
    case 'lists':
      return {
        data: await provider.tasks.getLists(),
        total: 0,
        limit: 0,
        offset: 0,
        hasMore: false,
      };
    case 'drive':
      return provider.drive.getFiles(options as DriveQuery);
  }
}

/** Output result as AI-friendly JSON with schema metadata */
function outputAi(cmd: DataCmd, result: CliResult) {
  const schema = SCHEMA[cmd];
  console.log(
    JSON.stringify(
      {
        meta: {
          command: cmd,
          total: result.total,
          limit: result.limit,
          offset: result.offset,
          hasMore: result.hasMore,
          schema,
        },
        data: result.data,
      },
      null,
      2
    )
  );
}

/** Output result as human-readable formatted text */
function outputHuman(cmd: DataCmd, result: CliResult) {
  const data = result.data;
  if (!Array.isArray(data) || data.length === 0) {
    console.log('No results');
    return;
  }
  const formatters: Record<DataCmd, (d: unknown[]) => void> = {
    calendars: formatCalendars,
    calendar: formatCalendar,
    emails: formatEmails,
    tasks: formatTasks,
    lists: formatLists,
    drive: formatDrive,
  };
  formatters[cmd](data);
}

const isMainModule = process.argv[1]?.endsWith('cli.ts');
if (isMainModule) {
  main().catch((err) => {
    console.error(err.message);
    process.exit(1);
  });
}
