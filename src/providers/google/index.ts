import type { OAuth2Client } from 'google-auth-library';
import { google } from 'googleapis';
import type {
  CalendarEvent,
  CalendarProvider,
  Email,
  EmailProvider,
  Provider,
  Task,
  TaskProvider,
} from '../base.js';

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

class GoogleCalendar implements CalendarProvider {
  constructor(private auth: OAuth2Client) {}

  async getEvents(from: Date, to: Date): Promise<CalendarEvent[]> {
    const calendar = google.calendar({ version: 'v3', auth: this.auth });
    const response = await calendar.events.list({
      calendarId: 'primary',
      timeMin: from.toISOString(),
      timeMax: to.toISOString(),
      singleEvents: true,
      orderBy: 'startTime',
    });

    return (response.data.items || []).map((event) => ({
      id: event.id || '',
      title: event.summary || '',
      start: new Date(event.start?.dateTime || event.start?.date || ''),
      end: new Date(event.end?.dateTime || event.end?.date || ''),
      location: event.location,
      attendees: event.attendees?.map((a) => a.email || ''),
      provider: 'google',
    }));
  }
}

class GoogleEmail implements EmailProvider {
  constructor(private auth: OAuth2Client) {}

  async getEmails(limit: number): Promise<Email[]> {
    const gmail = google.gmail({ version: 'v1', auth: this.auth });
    const response = await gmail.users.messages.list({
      userId: 'me',
      maxResults: limit,
    });

    const messages = await Promise.all(
      (response.data.messages || []).map(async (msg) => {
        const detail = await gmail.users.messages.get({
          userId: 'me',
          id: msg.id || '',
        });
        const headers = detail.data.payload?.headers || [];
        return {
          id: detail.data.id || '',
          from: headers.find((h) => h.name === 'From')?.value || '',
          to: [headers.find((h) => h.name === 'To')?.value || ''],
          subject: headers.find((h) => h.name === 'Subject')?.value || '',
          body: detail.data.snippet || '',
          date: new Date(Number.parseInt(detail.data.internalDate || '0')),
          read: !detail.data.labelIds?.includes('UNREAD'),
          provider: 'google',
        };
      })
    );

    return messages;
  }
}

class GoogleTasks implements TaskProvider {
  constructor(private auth: OAuth2Client) {}

  async getTasks(): Promise<Task[]> {
    const tasks = google.tasks({ version: 'v1', auth: this.auth });
    const response = await tasks.tasks.list({ tasklist: '@default' });

    return (response.data.items || []).map((task) => ({
      id: task.id || '',
      title: task.title || '',
      done: task.status === 'completed',
      due: task.due ? new Date(task.due) : undefined,
      provider: 'google',
    }));
  }
}
