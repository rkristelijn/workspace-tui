/**
 * Google Workspace provider — facade for calendar, email, and tasks.
 */
import { google } from 'googleapis';
import type { CalendarProvider, EmailProvider, Provider, TaskProvider } from '../../data/types.js';
import { GoogleCalendar } from './calendar.js';
import { GoogleEmail } from './email.js';
import type { GoogleCredentials } from './helpers.js';
import { GoogleTasks } from './tasks.js';

export type { GoogleCredentials } from './helpers.js';
export { paginate } from './helpers.js';

/** Google Workspace provider — calendar, email, and tasks via googleapis */
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
