import type { OAuth2Client } from 'google-auth-library';
import { google } from 'googleapis';
import type {
  Calendar,
  CalendarEvent,
  CalendarProvider,
  Email,
  EmailProvider,
  PaginatedResult,
  Provider,
  Task,
  TaskList,
  TaskProvider,
} from '../../data/types.js';

type GoogleCredentials = {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
};

export class GoogleProvider implements Provider {
  name = 'google';
  calendar: CalendarProvider;
  email: EmailProvider;
  tasks: TaskProvider;

  constructor(credentials: GoogleCredentials) {
    const auth = new google.auth.OAuth2(credentials.clientId, credentials.clientSecret);
    auth.setCredentials({ refresh_token: credentials.refreshToken });

    this.calendar = new GoogleCalendar(auth);
    this.email = new GoogleEmail(auth);
    this.tasks = new GoogleTasks(auth);
  }
}

// ============ Shared Helpers ============

function paginate<T>(items: T[], offset: number, limit: number): PaginatedResult<T> {
  return {
    data: items.slice(offset, offset + limit),
    total: items.length,
    limit,
    offset,
    hasMore: offset + limit < items.length,
  };
}

function sortByDate(order: 'asc' | 'desc' | undefined, getDate: (item: any) => number) {
  return (a: any, b: any) => (order === 'desc' ? getDate(b) - getDate(a) : getDate(a) - getDate(b));
}

// ============ Calendar ============

class GoogleCalendar implements CalendarProvider {
  constructor(private auth: OAuth2Client) {}

  async getCalendars(): Promise<Calendar[]> {
    const calendar = google.calendar({ version: 'v3', auth: this.auth });
    const response = await calendar.calendarList.list();

    return (response.data.items || []).map((cal) => ({
      id: cal.id || '',
      name: cal.summary || '',
      color: cal.backgroundColor || '#4285f4',
      primary: cal.primary || false,
      provider: 'google',
    }));
  }

  async getEvents(query: {
    from?: Date;
    to?: Date;
    calendarIds?: string[];
    search?: string;
    limit?: number;
    offset?: number;
    sortBy?: 'start' | 'end' | 'title';
    sortOrder?: 'asc' | 'desc';
  }): Promise<PaginatedResult<CalendarEvent>> {
    const calendarIds = query.calendarIds?.length ? query.calendarIds : ['primary'];
    const from = query.from || new Date();
    const to = query.to || new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    const allEvents: CalendarEvent[] = [];
    for (const calId of calendarIds) {
      const events = await this.fetchCalendarEvents(calId, from, to, query.search, query.sortBy);
      allEvents.push(...events);
    }

    this.sortEvents(allEvents, query.sortBy, query.sortOrder);
    return paginate(allEvents, query.offset || 0, query.limit || 50);
  }

  private async fetchCalendarEvents(
    calId: string,
    from: Date,
    to: Date,
    search?: string,
    sortBy?: string
  ): Promise<CalendarEvent[]> {
    const calendar = google.calendar({ version: 'v3', auth: this.auth });
    const response = await calendar.events.list({
      calendarId: calId,
      timeMin: from.toISOString(),
      timeMax: to.toISOString(),
      q: search,
      singleEvents: true,
      orderBy: sortBy === 'title' ? undefined : 'startTime',
      maxResults: 100,
    });

    return (response.data.items || []).map((event) => ({
      id: event.id || '',
      calendarId: calId,
      calendarName: event.organizer?.displayName || calId,
      title: event.summary || '',
      description: event.description || undefined,
      start: new Date(event.start?.dateTime || event.start?.date || ''),
      end: new Date(event.end?.dateTime || event.end?.date || ''),
      location: event.location || undefined,
      attendees: event.attendees?.map((a) => a.email || ''),
      color: event.colorId || undefined,
      provider: 'google' as const,
    }));
  }

  private sortEvents(events: CalendarEvent[], sortBy?: string, sortOrder?: string) {
    if (sortBy === 'title') {
      events.sort((a, b) =>
        sortOrder === 'desc' ? b.title.localeCompare(a.title) : a.title.localeCompare(b.title)
      );
    } else if (sortBy === 'end') {
      events.sort(sortByDate(sortOrder as 'asc' | 'desc', (e) => e.end.getTime()));
    } else {
      events.sort(sortByDate(sortOrder as 'asc' | 'desc', (e) => e.start.getTime()));
    }
  }
}

// ============ Email ============

class GoogleEmail implements EmailProvider {
  constructor(private auth: OAuth2Client) {}

  async getEmails(query: {
    search?: string;
    labels?: string[];
    read?: boolean;
    starred?: boolean;
    hasAttachment?: boolean;
    from?: string;
    to?: string;
    limit?: number;
    offset?: number;
    sortBy?: 'date' | 'subject' | 'from';
    sortOrder?: 'asc' | 'desc';
  }): Promise<PaginatedResult<Email>> {
    const gmail = google.gmail({ version: 'v1', auth: this.auth });
    const limit = query.limit || 20;
    const offset = query.offset || 0;

    let messages = await this.listMessageIds(gmail, query);
    messages = await this.filterByStatus(gmail, messages, query.read, query.starred);

    const paginatedIds = messages.slice(offset, offset + limit);
    const emails = await this.fetchEmailDetails(gmail, paginatedIds);

    this.sortEmails(emails, query.sortBy, query.sortOrder);

    return {
      data: emails,
      total: messages.length,
      limit,
      offset,
      hasMore: offset + limit < messages.length,
    };
  }

  private async listMessageIds(
    gmail: any,
    query: {
      search?: string;
      from?: string;
      to?: string;
      hasAttachment?: boolean;
      labels?: string[];
    }
  ): Promise<string[]> {
    let q = '';
    if (query.search) q += `${query.search} `;
    if (query.from) q += `from:${query.from} `;
    if (query.to) q += `to:${query.to} `;
    if (query.hasAttachment) q += 'has:attachment ';

    const response = await gmail.users.messages.list({
      userId: 'me',
      maxResults: 100,
      q: q.trim() || undefined,
      labelIds: query.labels,
    });

    return (response.data.messages || []).map((msg: any) => msg.id || '');
  }

  private async filterByStatus(
    gmail: any,
    messages: string[],
    read?: boolean,
    starred?: boolean
  ): Promise<string[]> {
    if (read === undefined && starred === undefined) return messages;

    const details = await Promise.all(
      messages.slice(0, 100).map((id) =>
        gmail.users.messages.get({ userId: 'me', id }).then((r: any) => ({
          id,
          read: !r.data.labelIds?.includes('UNREAD'),
          starred: r.data.labelIds?.includes('STARRED'),
        }))
      )
    );

    return details
      .filter((m) => read === undefined || m.read === read)
      .filter((m) => starred === undefined || m.starred === starred)
      .map((m) => m.id);
  }

  private async fetchEmailDetails(gmail: any, ids: string[]): Promise<Email[]> {
    return Promise.all(ids.map((id) => this.fetchSingleEmail(gmail, id)));
  }

  private async fetchSingleEmail(gmail: any, id: string): Promise<Email> {
    const detail = await gmail.users.messages.get({ userId: 'me', id });
    const headers = detail.data.payload?.headers || [];
    const attachments = this.parseAttachments(detail.data.payload?.parts || []);

    return {
      id: detail.data.id || '',
      threadId: detail.data.threadId,
      from: headers.find((h: any) => h.name === 'From')?.value || '',
      to:
        headers
          .find((h: any) => h.name === 'To')
          ?.value?.split(',')
          .map((s: string) => s.trim()) || [],
      cc: headers
        .find((h: any) => h.name === 'Cc')
        ?.value?.split(',')
        .map((s: string) => s.trim()),
      subject: headers.find((h: any) => h.name === 'Subject')?.value || '',
      body: detail.data.snippet || '',
      snippet: detail.data.snippet,
      date: new Date(Number.parseInt(detail.data.internalDate || '0', 10)),
      read: !detail.data.labelIds?.includes('UNREAD'),
      starred: detail.data.labelIds?.includes('STARRED'),
      labels: detail.data.labelIds || [],
      attachments,
      provider: 'google' as const,
    };
  }

  private parseAttachments(parts: any[]): Email['attachments'] {
    const attachments: Email['attachments'] = [];
    for (const part of parts) {
      if (part.filename && part.body?.attachmentId) {
        attachments.push({
          id: part.body.attachmentId,
          filename: part.filename,
          mimeType: part.mimeType || 'application/octet-stream',
          size: part.body.size || 0,
        });
      }
    }
    return attachments;
  }

  private sortEmails(emails: Email[], sortBy?: string, sortOrder?: string) {
    if (!sortBy) return;
    emails.sort((a, b) => {
      let cmp = 0;
      if (sortBy === 'date') cmp = a.date.getTime() - b.date.getTime();
      else if (sortBy === 'subject') cmp = a.subject.localeCompare(b.subject);
      else if (sortBy === 'from') cmp = a.from.localeCompare(b.from);
      return sortOrder === 'desc' ? -cmp : cmp;
    });
  }

  async getAttachment(messageId: string, attachmentId: string) {
    const gmail = google.gmail({ version: 'v1', auth: this.auth });
    const response = await gmail.users.messages.attachments.get({
      userId: 'me',
      messageId,
      id: attachmentId,
    });

    if (!response.data.data) return null;

    return {
      id: attachmentId,
      filename: '',
      mimeType: 'application/octet-stream',
      size: response.data.size || 0,
    };
  }
}

// ============ Tasks ============

class GoogleTasks implements TaskProvider {
  constructor(private auth: OAuth2Client) {}

  async getLists(): Promise<TaskList[]> {
    const tasks = google.tasks({ version: 'v1', auth: this.auth });
    const response = await tasks.tasklists.list();

    return (response.data.items || []).map((list) => ({
      id: list.id || '',
      name: list.title || '',
      provider: 'google' as const,
    }));
  }

  async getTasks(query: {
    listIds?: string[];
    search?: string;
    done?: boolean;
    limit?: number;
    offset?: number;
    sortBy?: 'due' | 'title' | 'created';
    sortOrder?: 'asc' | 'desc';
  }): Promise<PaginatedResult<Task>> {
    const listIds = query.listIds?.length ? query.listIds : ['@default'];
    const allTasks: Task[] = [];

    for (const listId of listIds) {
      const tasks = await this.fetchTasksForList(listId, query.search, query.done);
      allTasks.push(...tasks);
    }

    this.sortTasks(allTasks, query.sortBy, query.sortOrder);
    return paginate(allTasks, query.offset || 0, query.limit || 50);
  }

  private async fetchTasksForList(
    listId: string,
    search?: string,
    done?: boolean
  ): Promise<Task[]> {
    const tasks = google.tasks({ version: 'v1', auth: this.auth });
    const response = await tasks.tasks.list({
      tasklist: listId,
      showCompleted: true,
      showDeleted: false,
      maxResults: 100,
    });

    const items = response.data.items || [];
    const subtaskMap = this.buildSubtaskMap(items);

    return items
      .filter((task) => !task.parent)
      .filter((task) => !search || task.title?.toLowerCase().includes(search.toLowerCase()))
      .filter((task) => done === undefined || (task.status === 'completed') === done)
      .map((task) => ({
        id: task.id || '',
        listId,
        listName: '',
        title: task.title || '',
        notes: task.notes || undefined,
        done: task.status === 'completed',
        due: task.due ? new Date(task.due) : undefined,
        subtasks: subtaskMap.get(task.id || '') || [],
        parentId: task.parent || undefined,
        provider: 'google' as const,
      }));
  }

  private buildSubtaskMap(items: any[]): Map<string, Task['subtasks']> {
    const map: Map<string, Task['subtasks']> = new Map();
    for (const item of items) {
      if (item.parent) {
        if (!map.has(item.parent)) map.set(item.parent, []);
        map.get(item.parent)?.push({
          id: item.id || '',
          title: item.title || '',
          done: item.status === 'completed',
        });
      }
    }
    return map;
  }

  private sortTasks(tasks: Task[], sortBy?: string, sortOrder?: string) {
    if (sortBy === 'title') {
      tasks.sort((a, b) =>
        sortOrder === 'desc' ? b.title.localeCompare(a.title) : a.title.localeCompare(b.title)
      );
    } else {
      tasks.sort((a, b) => this.compareDue(a, b, sortOrder));
    }
  }

  private compareDue(a: Task, b: Task, sortOrder?: string): number {
    if (!a.due && !b.due) return 0;
    if (!a.due) return sortOrder === 'desc' ? -1 : 1;
    if (!b.due) return sortOrder === 'desc' ? 1 : -1;
    return sortOrder === 'desc'
      ? b.due.getTime() - a.due.getTime()
      : a.due.getTime() - b.due.getTime();
  }
}
