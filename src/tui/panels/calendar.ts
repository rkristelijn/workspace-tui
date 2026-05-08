/**
 * Calendar panel
 */

import blessed from 'blessed';
import type { CalendarEvent } from '../../data/types.js';

export class CalendarPanel {
  private box: blessed.Widgets.BoxElement;
  private list: blessed.Widgets.ListElement;

  constructor(
    screen: blessed.Widgets.Screen,
    row: number,
    col: number,
    rowSpan = 1,
    colSpan = 1,
    options: blessed.Widgets.BoxOptions = {}
  ) {
    this.box = blessed.box({
      ...options,
      parent: screen,
      top: `${row * 40}%`,
      left: `${col * 50}%`,
      width: `${colSpan * 50}%`,
      height: `${rowSpan * 50}%`,
    });

    this.list = blessed.list({
      parent: this.box,
      top: 0,
      left: 0,
      width: '100%',
      height: '100%',
      style: {
        selected: { bg: 'blue' },
      },
    });
  }

  setEvents(events: CalendarEvent[]): void {
    this.list.setItems(events.map((e) => `${e.start.toLocaleTimeString()} ${e.title}`));
  }

  focus(): void {
    this.box.focus();
  }
}
