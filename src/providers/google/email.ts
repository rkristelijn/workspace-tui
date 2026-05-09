/**
 * Google Email provider — fetches emails from Gmail API.
 */
import type { OAuth2Client } from 'google-auth-library';
import { type gmail_v1, google } from 'googleapis';
import type { Email, EmailProvider, PaginatedResult } from '../../data/types.js';

/** Gmail implementation */
export class GoogleEmail implements EmailProvider {
  constructor(private auth: OAuth2Client) {}

  /** Fetch emails with filtering, pagination, and sorting */
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

  /** List email message IDs matching the query criteria */
  private async listMessageIds(
    gmail: gmail_v1.Gmail,
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

    return (response.data.messages || []).map((msg) => msg.id || '');
  }

  /** Filter message IDs by read and starred status */
  private async filterByStatus(
    gmail: gmail_v1.Gmail,
    messages: string[],
    read?: boolean,
    starred?: boolean
  ): Promise<string[]> {
    if (read === undefined && starred === undefined) return messages;

    const details = await Promise.all(
      messages.slice(0, 100).map(async (id) => {
        const r = await gmail.users.messages.get({ userId: 'me', id });
        return {
          id,
          read: !r.data.labelIds?.includes('UNREAD'),
          starred: r.data.labelIds?.includes('STARRED'),
        };
      })
    );

    return details
      .filter((m) => read === undefined || m.read === read)
      .filter((m) => starred === undefined || m.starred === starred)
      .map((m) => m.id);
  }

  /** Fetch full details for multiple emails by their IDs */
  private async fetchEmailDetails(gmail: gmail_v1.Gmail, ids: string[]): Promise<Email[]> {
    return Promise.all(ids.map((id) => this.fetchSingleEmail(gmail, id)));
  }

  /** Fetch a single email with all its details */
  private async fetchSingleEmail(gmail: gmail_v1.Gmail, id: string): Promise<Email> {
    const detail = await gmail.users.messages.get({ userId: 'me', id });
    const headers = detail.data.payload?.headers ?? [];
    const attachments = this.parseAttachments(detail.data.payload?.parts ?? []);

    return {
      id: detail.data.id ?? '',
      threadId: detail.data.threadId ?? undefined,
      from: this.getHeader(headers, 'From'),
      to: this.getHeaderList(headers, 'To'),
      cc: this.getHeaderList(headers, 'Cc'),
      subject: this.getHeader(headers, 'Subject'),
      body: detail.data.snippet ?? '',
      snippet: detail.data.snippet ?? undefined,
      date: new Date(Number.parseInt(detail.data.internalDate ?? '0', 10)),
      read: detail.data.labelIds?.includes('UNREAD') === false,
      starred: detail.data.labelIds?.includes('STARRED') === true,
      labels: detail.data.labelIds ?? [],
      attachments,
      provider: 'google' as const,
    };
  }

  /** Get a single header value by name */
  private getHeader(headers: unknown[], name: string): string {
    interface Header {
      name?: string;
      value?: string;
    }
    return (headers as Header[]).find((h) => h.name === name)?.value ?? '';
  }

  /** Get a list of header values by name, split by comma */
  private getHeaderList(headers: unknown[], name: string): string[] {
    interface Header {
      name?: string;
      value?: string;
    }
    const value = (headers as Header[]).find((h) => h.name === name)?.value;
    return value?.split(',').map((s) => s.trim()) ?? [];
  }

  /** Extract attachment metadata from message parts */
  private parseAttachments(parts: gmail_v1.Schema$MessagePart[]): Email['attachments'] {
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

  /** Sort emails by the specified field and order */
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

  /** Download a specific email attachment */
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
