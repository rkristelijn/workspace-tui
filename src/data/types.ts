/**
 * Shared data types for workspace-tui
 */

// ============ Calendar ============

export interface CalendarEvent {
  id: string;
  calendarId: string;
  calendarName: string;
  title: string;
  description?: string;
  start: Date;
  end: Date;
  location?: string;
  attendees?: string[];
  color?: string;
  provider: string;
}

export interface Calendar {
  id: string;
  name: string;
  color: string;
  primary: boolean;
  provider: string;
}

export interface CalendarQuery {
  from?: Date;
  to?: Date;
  calendarIds?: string[];
  search?: string;
  limit?: number;
  offset?: number;
  sortBy?: 'start' | 'end' | 'title';
  sortOrder?: 'asc' | 'desc';
}

// ============ Tasks ============

export interface Task {
  id: string;
  listId: string;
  listName: string;
  title: string;
  notes?: string;
  done: boolean;
  due?: Date;
  priority?: 'high' | 'medium' | 'low';
  subtasks?: SubTask[];
  parentId?: string;
  provider: string;
}

export interface SubTask {
  id: string;
  title: string;
  done: boolean;
}

export interface TaskList {
  id: string;
  name: string;
  provider: string;
}

export interface TaskQuery {
  listIds?: string[];
  search?: string;
  done?: boolean;
  priority?: 'high' | 'medium' | 'low';
  hasSubtasks?: boolean;
  limit?: number;
  offset?: number;
  sortBy?: 'due' | 'title' | 'created';
  sortOrder?: 'asc' | 'desc';
}

// ============ Email ============

export interface Email {
  id: string;
  threadId?: string;
  from: string;
  to: string[];
  cc?: string[];
  subject: string;
  body: string;
  snippet?: string;
  date: Date;
  read: boolean;
  starred: boolean;
  labels?: string[];
  attachments?: Attachment[];
  provider: string;
}

export interface Attachment {
  id: string;
  filename: string;
  mimeType: string;
  size: number;
  downloadUrl?: string;
}

export interface EmailQuery {
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
}

// ============ Pagination ============

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
}

// ============ Provider Interfaces ============

export type CalendarProvider = {
  getCalendars(): Promise<Calendar[]>;
  getEvents(query: CalendarQuery): Promise<PaginatedResult<CalendarEvent>>;
};

export type EmailProvider = {
  getEmails(query: EmailQuery): Promise<PaginatedResult<Email>>;
  getAttachment(messageId: string, attachmentId: string): Promise<Attachment | null>;
};

export type TaskProvider = {
  getLists(): Promise<TaskList[]>;
  getTasks(query: TaskQuery): Promise<PaginatedResult<Task>>;
};

export type Provider = {
  name: string;
  calendar?: CalendarProvider;
  email?: EmailProvider;
  tasks?: TaskProvider;
};
