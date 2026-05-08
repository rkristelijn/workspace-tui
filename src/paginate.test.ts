import { describe, expect, it } from 'vitest';
import { paginate } from './providers/google/index.js';

describe('paginate', () => {
  const items = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  it('returns first page', () => {
    const result = paginate(items, 0, 3);
    expect(result.data).toEqual([1, 2, 3]);
    expect(result.total).toBe(10);
    expect(result.limit).toBe(3);
    expect(result.offset).toBe(0);
    expect(result.hasMore).toBe(true);
  });

  it('returns middle page', () => {
    const result = paginate(items, 3, 3);
    expect(result.data).toEqual([4, 5, 6]);
    expect(result.offset).toBe(3);
    expect(result.hasMore).toBe(true);
  });

  it('returns last page', () => {
    const result = paginate(items, 9, 3);
    expect(result.data).toEqual([10]);
    expect(result.hasMore).toBe(false);
  });

  it('returns empty when offset exceeds length', () => {
    const result = paginate(items, 20, 5);
    expect(result.data).toEqual([]);
    expect(result.hasMore).toBe(false);
  });

  it('returns all when limit exceeds length', () => {
    const result = paginate(items, 0, 100);
    expect(result.data).toEqual(items);
    expect(result.hasMore).toBe(false);
  });
});
