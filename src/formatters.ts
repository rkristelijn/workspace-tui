/**
 * Human-readable output formatters for CLI commands.
 */
import type { CalendarEvent, Email, Task } from './data/types.js';

/** Format calendar list for terminal output */
export function formatCalendars(data: unknown[]) {
  console.log('Calendars:');
  for (const c of data as Array<{ name: string; color: string; primary: boolean }>) {
    const primary = c.primary ? ' [PRIMARY]' : '';
    console.log(`  ${c.color} ${c.name}${primary}`);
  }
}

/** Format calendar events for terminal output */
export function formatCalendar(data: unknown[]) {
  for (const e of data as CalendarEvent[]) {
    const start = new Date(e.start).toLocaleString('nl-NL', {
      weekday: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
    const end = new Date(e.end).toLocaleString('nl-NL', { hour: '2-digit', minute: '2-digit' });
    const loc = e.location ? ` @ ${e.location}` : '';
    const cal = e.calendarName !== 'primary' ? ` [${e.calendarName}]` : '';
    console.log(`${start}-${end} ${e.title}${loc}${cal}`);
  }
}

/** Format emails for terminal output */
export function formatEmails(data: unknown[]) {
  for (const e of data as Email[]) {
    const unread = e.read ? '' : '[UNREAD]';
    const star = e.starred ? '★' : ' ';
    const date = new Date(e.date).toLocaleDateString('nl-NL');
    const from = e.from.split('<')[0].trim().substring(0, 20).padEnd(20);
    const subject = e.subject.substring(0, 45).padEnd(45);
    const labels = e.labels?.filter((l) => !l.startsWith('CATEGORY') && l !== 'INBOX').join(',');
    const labelStr = labels ? ` [${labels}]` : '';
    console.log(`${star}${unread} ${from} | ${subject} | ${date}${labelStr}`);
  }
}

/** Format tasks for terminal output */
export function formatTasks(data: unknown[]) {
  for (const t of data as Task[]) {
    const check = t.done ? '✓' : '○';
    const due = t.due ? ` (${new Date(t.due).toLocaleDateString('nl-NL')})` : '';
    const subtasks = t.subtasks?.length
      ? ` [${t.subtasks.filter((s) => !s.done).length}/${t.subtasks.length} sub]`
      : '';
    const list = t.listId !== '@default' ? ` [${t.listName || t.listId}]` : '';
    console.log(`${check} ${t.title}${due}${subtasks}${list}`);
  }
}

/** Format task lists for terminal output */
export function formatLists(data: unknown[]) {
  console.log('Task Lists:');
  for (const l of data as Array<{ name: string }>) {
    console.log(`  ${l.name}`);
  }
}
