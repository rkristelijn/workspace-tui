import { describe, expect, it } from 'vitest';
import { parseArgs, parseOptionalBool, parseOptions } from './cli.js';

describe('parseArgs', () => {
  it('returns --help for --help flag', () => {
    expect(parseArgs(['--help'])).toBe('--help');
  });

  it('returns command for valid commands', () => {
    expect(parseArgs(['calendars'])).toBe('calendars');
    expect(parseArgs(['calendar'])).toBe('calendar');
    expect(parseArgs(['emails'])).toBe('emails');
    expect(parseArgs(['tasks'])).toBe('tasks');
    expect(parseArgs(['lists'])).toBe('lists');
  });

  it('returns undefined for invalid command', () => {
    expect(parseArgs(['invalid'])).toBeUndefined();
    expect(parseArgs([])).toBeUndefined();
  });
});

describe('parseOptions', () => {
  it('returns defaults when no options given', () => {
    const { mode, options } = parseOptions(['calendar']);
    expect(mode).toBe('ai');
    expect(options.limit).toBe(20);
    expect(options.offset).toBe(0);
    expect(options.sortOrder).toBe('desc');
    expect(options.hasAttachment).toBe(false);
  });

  it('parses mode', () => {
    expect(parseOptions(['emails', '--mode=human']).mode).toBe('human');
    expect(parseOptions(['emails', '--mode=ai']).mode).toBe('ai');
  });

  it('parses limit and offset', () => {
    const { options } = parseOptions(['tasks', '--limit=5', '--offset=10']);
    expect(options.limit).toBe(5);
    expect(options.offset).toBe(10);
  });

  it('parses calendar-ids as array', () => {
    const { options } = parseOptions(['calendar', '--calendar-ids=a@b.com,c@d.com']);
    expect(options.calendarIds).toEqual(['a@b.com', 'c@d.com']);
  });

  it('parses list-ids as array', () => {
    const { options } = parseOptions(['tasks', '--list-ids=Jady,Zani']);
    expect(options.listIds).toEqual(['Jady', 'Zani']);
  });

  it('parses boolean flags', () => {
    const { options } = parseOptions([
      'emails',
      '--read=true',
      '--starred=false',
      '--has-attachment',
    ]);
    expect(options.read).toBe(true);
    expect(options.starred).toBe(false);
    expect(options.hasAttachment).toBe(true);
  });

  it('parses search', () => {
    const { options } = parseOptions(['emails', '--search=invoice']);
    expect(options.search).toBe('invoice');
  });

  it('parses sort options', () => {
    const { options } = parseOptions(['calendar', '--sort-by=title', '--sort-order=asc']);
    expect(options.sortBy).toBe('title');
    expect(options.sortOrder).toBe('asc');
  });
});

describe('parseOptionalBool', () => {
  it('returns undefined when flag not present', () => {
    expect(parseOptionalBool(['--other=x'], '--read')).toBeUndefined();
  });

  it('returns true for =true', () => {
    expect(parseOptionalBool(['--read=true'], '--read')).toBe(true);
  });

  it('returns false for =false', () => {
    expect(parseOptionalBool(['--read=false'], '--read')).toBe(false);
  });
});
