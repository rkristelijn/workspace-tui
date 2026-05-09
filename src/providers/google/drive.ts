/**
 * Google Drive provider — fetches files from Google Drive API.
 */
import type { OAuth2Client } from 'google-auth-library';
import { google } from 'googleapis';
import type { DriveFile, DriveProvider, DriveQuery, PaginatedResult } from '../../data/types.js';
import { paginate } from './helpers.js';

/** Google Drive implementation */
export class GoogleDrive implements DriveProvider {
  constructor(private auth: OAuth2Client) {}

  /** Fetch files with filtering, pagination, and sorting */
  async getFiles(query: DriveQuery): Promise<PaginatedResult<DriveFile>> {
    const drive = google.drive({ version: 'v3', auth: this.auth });
    const q = this.buildQuery(query);

    const response = await drive.files.list({
      q: q || undefined,
      pageSize: 100,
      fields: 'files(id, name, mimeType, size, modifiedTime, parents, webViewLink)',
      orderBy: this.buildOrderBy(query.sortBy, query.sortOrder),
    });

    const files: DriveFile[] = (response.data.files || []).map((f) => ({
      id: f.id || '',
      name: f.name || '',
      mimeType: f.mimeType || '',
      size: f.size ? Number(f.size) : undefined,
      modifiedTime: f.modifiedTime ? new Date(f.modifiedTime) : undefined,
      parentId: f.parents?.[0] || undefined,
      webViewLink: f.webViewLink || undefined,
      provider: 'google',
    }));

    return paginate(files, query.offset || 0, query.limit || 20);
  }

  /** Download file content by ID */
  async downloadFile(fileId: string): Promise<Buffer | null> {
    const drive = google.drive({ version: 'v3', auth: this.auth });
    try {
      const response = await drive.files.get(
        { fileId, alt: 'media' },
        { responseType: 'arraybuffer' }
      );
      return Buffer.from(response.data as ArrayBuffer);
    } catch {
      return null;
    }
  }

  /** Build Drive API query string from DriveQuery */
  private buildQuery(query: DriveQuery): string {
    const parts: string[] = ['trashed = false'];
    if (query.search) parts.push(`name contains '${query.search}'`);
    if (query.mimeType) parts.push(`mimeType = '${query.mimeType}'`);
    if (query.parentId) parts.push(`'${query.parentId}' in parents`);
    return parts.join(' and ');
  }

  /** Map sort options to Drive API orderBy format */
  private buildOrderBy(sortBy?: string, sortOrder?: string): string {
    const field = sortBy === 'size' ? 'quotaBytesUsed' : sortBy || 'modifiedTime';
    const dir = sortOrder === 'asc' ? '' : ' desc';
    return `${field}${dir}`;
  }
}
