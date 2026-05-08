/**
 * Email panel
 */

import blessed from 'blessed';
import type { Email } from '../../data/types.js';

export class EmailPanel {
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

  setEmails(emails: Email[]): void {
    this.list.setItems(emails.map((e) => `${e.from}: ${e.subject}`));
  }

  focus(): void {
    this.box.focus();
  }
}
