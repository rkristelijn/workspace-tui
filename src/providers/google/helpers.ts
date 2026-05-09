/**
 * Shared helpers for Google provider modules.
 */
import type { PaginatedResult } from '../../data/types.js';

/** Google API credentials with refresh token for offline access */
export type GoogleCredentials = {
  clientId: string;
  clientSecret: string;
  refreshToken: string;
};

/** Paginate an array with offset/limit and return metadata */
export function paginate<T>(items: T[], offset: number, limit: number): PaginatedResult<T> {
  return {
    data: items.slice(offset, offset + limit),
    total: items.length,
    limit,
    offset,
    hasMore: offset + limit < items.length,
  };
}

/** Create a comparator function for sorting items by date */
export function sortByDate<T>(order: 'asc' | 'desc' | undefined, getDate: (item: T) => number) {
  return (a: T, b: T) => (order === 'desc' ? getDate(b) - getDate(a) : getDate(a) - getDate(b));
}
