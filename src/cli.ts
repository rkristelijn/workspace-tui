/**
 * CLI orchestrator for workspace-tui.
 * Delegates parsing to cli-parser.ts and formatting to formatters.ts.
 */

import {
  type CliOptions,
  type CliResult,
  type Cmd,
  parseArgs,
  parseOptions,
  SCHEMA,
  USAGE,
} from './cli-parser.js';
import { loadConfig } from './config.js';
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

  if (!cmd) {
    console.error('Command required');
    console.log(USAGE.trim());
    process.exit(1);
  }

  const { mode, options } = parseOptions(args);
  const config = loadConfig();
  const credentials = await getCredentials(config);

  const provider = new GoogleProvider(credentials);
  const result = await getData(provider, cmd, options);

  if (mode === 'ai') {
    outputAi(cmd, result);
  } else {
    outputHuman(cmd, result);
  }
}

/** Get Google credentials from config or environment */
async function getCredentials(config: ReturnType<typeof loadConfig>) {
  let credentials = config.providers.google;

  if (!credentials) {
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
    if (!clientId || !clientSecret) {
      console.error('Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET in .env');
      process.exit(1);
    }
    credentials = await authenticate(clientId, clientSecret);
    config.providers.google = credentials;
  }

  return credentials;
}

/** Fetch data from provider based on command and options */
async function getData(
  provider: GoogleProvider,
  cmd: Cmd,
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
function outputAi(cmd: Cmd, result: CliResult) {
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
function outputHuman(cmd: Cmd, result: CliResult) {
  const data = result.data;
  if (!Array.isArray(data) || data.length === 0) {
    console.log('No results');
    return;
  }
  const formatters: Record<Cmd, (d: unknown[]) => void> = {
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
