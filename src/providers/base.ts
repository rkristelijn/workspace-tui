export type CalendarEvent = {
  id: string;
  title: string;
  start: Date;
  end: Date;
  location?: string;
  attendees?: string[];
  provider: string;
};

export type Email = {
  id: string;
  from: string;
  to: string[];
  subject: string;
  body: string;
  date: Date;
  read: boolean;
  provider: string;
};

export type Task = {
  id: string;
  title: string;
  done: boolean;
  due?: Date;
  priority?: 'high' | 'medium' | 'low';
  provider: string;
};

export type CalendarProvider = {
  getEvents(from: Date, to: Date): Promise<CalendarEvent[]>;
};

export type EmailProvider = {
  getEmails(limit: number): Promise<Email[]>;
};

export type TaskProvider = {
  getTasks(): Promise<Task[]>;
};

export type Provider = {
  name: string;
  calendar?: CalendarProvider;
  email?: EmailProvider;
  tasks?: TaskProvider;
};
