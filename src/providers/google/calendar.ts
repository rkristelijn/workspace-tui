/**
 * Google Calendar provider — fetches events from Google Calendar API.
 */
import type { OAuth2Client } from 'google-auth-library';
import { google } from 'googleapis';
import type {
  Calendar,
  CalendarEvent,
  CalendarProvider,
  PaginatedResult,
} from '../../data/types.js';
import { paginate, sortByDate } from './helpers.js';

/** Google Calendar implementation */
export class GoogleCalendar implements CalendarProvider {
  constructor(private auth: OAuth2Client) {}

  /** Fetch all calendars the user has access to */
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

  /** Fetch calendar events with pagination and sorting */
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

  /** Fetch events from a single calendar within the given time range */
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

  /** Sort events by the specified field and order */
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
