/**
 * CLI argument parsing and schema definitions.
 */

export type Cmd =
  | 'calendars'
  | 'calendar'
  | 'emails'
  | 'tasks'
  | 'lists'
  | 'drive'
  | 'download'
  | 'logout'
  | 'task-create'
  | 'task-done'
  | 'task-update'
  | 'task-move'
  | 'task-delete'
  | 'event-create'
  | 'event-update'
  | 'event-delete';
/** Commands that return data (used for output formatting) */
export type DataCmd = Exclude<
  Cmd,
  | 'download'
  | 'logout'
  | 'task-create'
  | 'task-done'
  | 'task-update'
  | 'task-move'
  | 'task-delete'
  | 'event-create'
  | 'event-update'
  | 'event-delete'
>;
export type Mode = 'ai' | 'human';

export interface CliOptions {
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

export type CliResult = {
  data: unknown[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
};

export const USAGE = `
workspace-tui CLI

Usage: pnpm cli <command> [options]

Commands:
  calendars   List all calendars
  calendar    List calendar events
  emails      List emails
  tasks       List tasks
  lists       List task lists
  drive       List drive files
  download    Download a drive file (--id=FILE_ID --out=path)
  logout      Remove stored credentials

  task-create   Create task (--list-id= --title= [--due= --notes=])
  task-done     Mark task done (--list-id= --id=)
  task-update   Update task (--list-id= --id= [--title= --due= --done=])
  task-move     Reorder task (--list-id= --id= [--after=])
  task-delete   Delete task (--list-id= --id=)

  event-create  Create event (--calendar-id= --title= --start= --end=)
  event-update  Update event (--calendar-id= --id= [--title= --start= --end=])
  event-delete  Delete event (--calendar-id= --id=)

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

export const SCHEMA = {
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
  drive: {
    description: 'Paginated drive files',
    parse: 'data.map(f => ({ id: f.id, name: f.name, mimeType: f.mimeType, size: f.size }))',
    fields: 'id, name, mimeType, size, modifiedTime, parentId, webViewLink, provider',
  },
};

/** Parse CLI arguments and return the command name */
export function parseArgs(args: string[]): Cmd | '--help' | undefined {
  const cmd = args[0];
  if (cmd === '--help') return '--help';
  const valid: Cmd[] = [
    'calendars',
    'calendar',
    'emails',
    'tasks',
    'lists',
    'drive',
    'download',
    'logout',
    'task-create',
    'task-done',
    'task-update',
    'task-move',
    'task-delete',
    'event-create',
    'event-update',
    'event-delete',
  ];
  if (valid.includes(cmd as Cmd)) return cmd as Cmd;
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
