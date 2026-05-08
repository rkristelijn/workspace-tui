/**
 * Status bar widget
 */

import blessed from 'blessed';

export class StatusBar {
  private bar: blessed.Widgets.BoxElement;

  constructor(parent: blessed.Widgets.Screen) {
    this.bar = blessed.box({
      parent,
      bottom: 0,
      left: 0,
      width: '100%',
      height: 1,
      style: {
        bg: 'blue',
        fg: 'white',
      },
      content: 'workspace-tui | Tab: next panel | q: quit | ?: help',
    });
  }

  setMessage(message: string): void {
    this.bar.setContent(message);
  }
}
