/**
 * CLI for workspace-tui
 * Two output modes: AI (JSON with hints) and Human (compact)
 */

import { loadConfig } from './config.js';
import type {
  CalendarEvent,
  CalendarQuery,
  Email,
  EmailQuery,
  Task,
  TaskQuery,
} from './data/types.js';
import {
  formatCalendar,
  formatCalendars,
  formatEmails,
  formatLists,
  formatTasks,
} from './formatters.js';
import { authenticate } from './providers/google/auth.js';
import { GoogleProvider } from './providers/google/index.js';

const USAGE = `
workspace-tui CLI

Usage: node src/cli.ts <command> [options]

Commands:
  calendars   List all calendars
  calendar    List calendar events
  emails      List emails
  tasks       List tasks
  lists       List task lists

Options:
  --mode ai|human       Output format (default: ai)
  --limit N             Max items (default: 20)
  --offset N            Pagination offset (default: 0)
  --sort-by FIELD       Sort field (see per command)
  --sort-order asc|desc Sort order (default: desc)
  --search TEXT         Search query
  --calendar-ids IDS    Filter by calendar IDs (comma-separated)
  --list-ids IDS        Filter by task list IDs (comma-separated)
  --labels IDS          Filter by email labels (comma-separated)
  --read true|false     Filter by read status
  --starred true|false  Filter by starred status
  --has-attachment      Filter emails with attachments
  --from ADDRESS        Filter emails from address
  --to ADDRESS          Filter emails to address
  --done true|false     Filter tasks by done status
  --help                Show this help
`;

type Cmd = 'calendars' | 'calendar' | 'emails' | 'tasks' | 'lists';
type Mode = 'ai' | 'human';

const SCHEMA = {
  calendars: {
    description: 'Array of calendar objects',
    parse: 'data.map(c => ({ id: c.id, name: c.name, color: c.color, primary: c.primary }))',
    fields: 'id, name, color, primary, provider',
  },
  calendar: {
    description: 'Paginated calendar events',
    parse:
      'data.map(e => ({ id: e.id, title: e.title, start: e.start, end: e.end, location: e.location, calendarId: e.calendarId }))',
    fields:
      'id, calendarId, calendarName, title, description, start, end, location, attendees, color, provider',
  },
  emails: {
    description: 'Paginated email messages',
    parse:
      'data.map(e => ({ id: e.id, from: e.from, to: e.to, subject: e.subject, date: e.date, read: e.read, labels: e.labels }))',
    fields:
      'id, threadId, from, to, cc, subject, body, snippet, date, read, starred, labels, attachments, provider',
  },
  tasks: {
    description: 'Paginated tasks',
    parse:
      'data.map(t => ({ id: t.id, title: t.title, done: t.done, due: t.due, listId: t.listId }))',
    fields: 'id, listId, listName, title, notes, done, due, priority, subtasks, parentId, provider',
  },
  lists: {
    description: 'Array of task lists',
    parse: 'data.map(l => ({ id: l.id, name: l.name }))',
    fields: 'id, name, provider',
  },
};

interface CliOptions {
  limit: number;
  offset: number;
  sortBy?: string;
  sortOrder: 'asc' | 'desc';
  search?: string;
  calendarIds?: string[];
  listIds?: string[];
  labels?: string[];
  read?: boolean;
  starred?: boolean;
  hasAttachment: boolean;
  from?: string;
  to?: string;
  done?: boolean;
}

type CliResult = {
  data: unknown[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
};

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

/** Parse CLI arguments and return the command name */
export function parseArgs(args: string[]): Cmd | '--help' | undefined {
  const cmd = args[0];
  if (cmd === '--help') return '--help';
  if (['calendars', 'calendar', 'emails', 'tasks', 'lists'].includes(cmd)) return cmd as Cmd;
  return undefined;
}

/** Parse CLI options from arguments and return mode and options object */
export function parseOptions(args: string[]) {
  const mode = (args.find((a) => a.startsWith('--mode'))?.split('=')[1] || 'ai') as Mode;
  const limit = parseInt(args.find((a) => a.startsWith('--limit'))?.split('=')[1] || '20', 10);
  const offset = parseInt(args.find((a) => a.startsWith('--offset'))?.split('=')[1] || '0', 10);
  const sortBy = args.find((a) => a.startsWith('--sort-by'))?.split('=')[1];
  const sortOrder = (args.find((a) => a.startsWith('--sort-order'))?.split('=')[1] || 'desc') as
    | 'asc'
    | 'desc';
  const search = args.find((a) => a.startsWith('--search'))?.split('=')[1];

  return {
    mode,
    options: {
      limit,
      offset,
      sortBy,
      sortOrder,
      search,
      calendarIds: args
        .find((a) => a.startsWith('--calendar-ids'))
        ?.split('=')[1]
        ?.split(','),
      listIds: args
        .find((a) => a.startsWith('--list-ids'))
        ?.split('=')[1]
        ?.split(','),
      labels: args
        .find((a) => a.startsWith('--labels'))
        ?.split('=')[1]
        ?.split(','),
      read: parseOptionalBool(args, '--read'),
      starred: parseOptionalBool(args, '--starred'),
      hasAttachment: args.some((a) => a.startsWith('--has-attachment')),
      from: args.find((a) => a.startsWith('--from'))?.split('=')[1],
      to: args.find((a) => a.startsWith('--to'))?.split('=')[1],
      done: parseOptionalBool(args, '--done'),
    },
  };
}

/** Parse optional boolean flag from arguments */
export function parseOptionalBool(args: string[], flag: string): boolean | undefined {
  const val = args.find((a) => a.startsWith(`${flag}=`))?.split('=')[1];
  if (val === undefined) return undefined;
  return val === 'true';
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
