/**
 * Provider type definitions
 * Defines interfaces for Calendar, Email, and Tasks providers
 * Uses Interface Segregation Principle - providers implement only what they support
 */

/**
 * Calendar event from any provider
 * Represents a single calendar event with time, location, and attendees
 */
export type CalendarEvent = {
  /** Unique event identifier */
  id: string;
  /** Event title/summary */
  title: string;
  /** Event start time */
  start: Date;
  /** Event end time */
  end: Date;
  /** Optional event location */
  location?: string;
  /** Optional list of attendee email addresses */
  attendees?: string[];
  /** Provider name (e.g., 'google', 'microsoft') */
  provider: string;
};

/**
 * Email message from any provider
 * Represents a single email with sender, recipients, and content
 */
export type Email = {
  /** Unique message identifier */
  id: string;
  /** Sender email address */
  from: string;
  /** List of recipient email addresses */
  to: string[];
  /** Email subject line */
  subject: string;
  /** Email body content (plain text or snippet) */
  body: string;
  /** Message date/time */
  date: Date;
  /** Whether message has been read */
  read: boolean;
  /** Provider name (e.g., 'google', 'microsoft') */
  provider: string;
};

/**
 * Task from any provider
 * Represents a single task/todo item
 */
export type Task = {
  /** Unique task identifier */
  id: string;
  /** Task title/description */
  title: string;
  /** Whether task is completed */
  done: boolean;
  /** Optional due date */
  due?: Date;
  /** Optional priority level */
  priority?: 'high' | 'medium' | 'low';
  /** Provider name (e.g., 'google', 'microsoft') */
  provider: string;
};

/**
 * Calendar provider interface (read-only for MVP)
 * Provides access to calendar events
 */
export type CalendarProvider = {
  /**
   * Get calendar events within a date range
   * @param from - Start date (inclusive)
   * @param to - End date (exclusive)
   * @returns Promise resolving to array of calendar events
   */
  getEvents(from: Date, to: Date): Promise<CalendarEvent[]>;
};

/**
 * Email provider interface (read-only for MVP)
 * Provides access to email messages
 */
export type EmailProvider = {
  /**
   * Get recent email messages
   * @param limit - Maximum number of messages to return
   * @returns Promise resolving to array of email messages
   */
  getEmails(limit: number): Promise<Email[]>;
};

/**
 * Task provider interface (read-only for MVP)
 * Provides access to tasks/todos
 */
export type TaskProvider = {
  /**
   * Get all tasks
   * @returns Promise resolving to array of tasks
   */
  getTasks(): Promise<Task[]>;
};

/**
 * Main provider interface
 * Providers implement only the capabilities they support (Interface Segregation Principle)
 * @example
 * // Google supports all three
 * const google: Provider = {
 *   name: 'google',
 *   calendar: googleCalendar,
 *   email: googleEmail,
 *   tasks: googleTasks
 * };
 *
 * // Proton might only support calendar and email
 * const proton: Provider = {
 *   name: 'proton',
 *   calendar: protonCalendar,
 *   email: protonEmail
 * };
 */
export type Provider = {
  /** Provider name (e.g., 'google', 'microsoft', 'proton') */
  name: string;
  /** Optional calendar provider */
  calendar?: CalendarProvider;
  /** Optional email provider */
  email?: EmailProvider;
  /** Optional task provider */
  tasks?: TaskProvider;
};
