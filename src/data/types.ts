/**
 * Shared data types for workspace-tui
 */

// ============ Calendar ============

/** A calendar event with time, location, and attendees */
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

/** A calendar resource with name, color, and provider info */
export interface Calendar {
  id: string;
  name: string;
  color: string;
  primary: boolean;
  provider: string;
}

/** Query parameters for filtering and sorting calendar events */
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

/** A task item with title, status, and optional due date */
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

/** A subtask nested within a parent task */
export interface SubTask {
  id: string;
  title: string;
  done: boolean;
}

/** A task list container for grouping tasks */
export interface TaskList {
  id: string;
  name: string;
  provider: string;
}

/** Query parameters for filtering and sorting tasks */
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

/** An email message with headers, body, and optional attachments */
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

/** An email attachment with metadata and download URL */
export interface Attachment {
  id: string;
  filename: string;
  mimeType: string;
  size: number;
  downloadUrl?: string;
}

/** Query parameters for filtering and sorting emails */
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

// ============ Drive ============

/** A file or folder in cloud storage */
export interface DriveFile {
  id: string;
  name: string;
  mimeType: string;
  size?: number;
  modifiedTime?: Date;
  parentId?: string;
  webViewLink?: string;
  provider: string;
}

/** Query parameters for filtering and sorting drive files */
export interface DriveQuery {
  search?: string;
  mimeType?: string;
  parentId?: string;
  limit?: number;
  offset?: number;
  sortBy?: 'name' | 'modifiedTime' | 'size';
  sortOrder?: 'asc' | 'desc';
}

// ============ Pagination ============

/** Paginated response with data, total count, and pagination state */
export interface PaginatedResult<T> {
  data: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
}

// ============ Provider Interfaces ============

/** Calendar provider interface for fetching calendars and events */
export type CalendarProvider = {
  getCalendars(): Promise<Calendar[]>;
  getEvents(query: CalendarQuery): Promise<PaginatedResult<CalendarEvent>>;
  createEvent(
    calendarId: string,
    event: { title: string; start: string; end: string; location?: string; description?: string }
  ): Promise<CalendarEvent>;
  updateEvent(
    calendarId: string,
    eventId: string,
    updates: {
      title?: string;
      start?: string;
      end?: string;
      location?: string;
      description?: string;
    }
  ): Promise<CalendarEvent>;
  deleteEvent(calendarId: string, eventId: string): Promise<void>;
};

/** Email provider interface for fetching emails and attachments */
export type EmailProvider = {
  getEmails(query: EmailQuery): Promise<PaginatedResult<Email>>;
  getAttachment(messageId: string, attachmentId: string): Promise<Attachment | null>;
};

/** Task provider interface for fetching lists and tasks */
export type TaskProvider = {
  getLists(): Promise<TaskList[]>;
  getTasks(query: TaskQuery): Promise<PaginatedResult<Task>>;
  createTask(listId: string, task: { title: string; notes?: string; due?: string }): Promise<Task>;
  updateTask(
    listId: string,
    taskId: string,
    updates: { title?: string; notes?: string; due?: string; done?: boolean }
  ): Promise<Task>;
  moveTask(listId: string, taskId: string, previousId?: string): Promise<void>;
  deleteTask(listId: string, taskId: string): Promise<void>;
};

/** Drive provider interface for fetching and downloading files */
export type DriveProvider = {
  getFiles(query: DriveQuery): Promise<PaginatedResult<DriveFile>>;
  downloadFile(fileId: string): Promise<Buffer | null>;
};

/** Unified provider combining calendar, email, task, and drive capabilities */
export type Provider = {
  name: string;
  calendar?: CalendarProvider;
  email?: EmailProvider;
  tasks?: TaskProvider;
  drive?: DriveProvider;
};
