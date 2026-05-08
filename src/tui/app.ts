/**
 * Main TUI application with dynamic grid-based layout
 */

import blessed from 'blessed';
import { CalendarPanel } from './panels/calendar.js';
import { EmailPanel } from './panels/email.js';
import { TasksPanel } from './panels/tasks.js';

type PanelType = 'calendar' | 'email' | 'tasks';

interface PanelConfig {
  id: string;
  type: PanelType;
  row: number;
  col: number;
  rowSpan?: number;
  colSpan?: number;
}

interface LayoutConfig {
  rows: number;
  cols: number;
  panels: PanelConfig[];
}

const DEFAULT_LAYOUT: LayoutConfig = {
  rows: 2,
  cols: 2,
  panels: [
    { id: 'calendar-main', type: 'calendar', row: 0, col: 0, rowSpan: 2 },
    { id: 'email-main', type: 'email', row: 0, col: 1 },
    { id: 'tasks-side', type: 'tasks', row: 1, col: 1 },
  ],
};

export class TuiApp {
  private screen: blessed.Widgets.Screen;
  private panels: Map<string, CalendarPanel | EmailPanel | TasksPanel> = new Map();
  private layout: LayoutConfig;

  constructor(layout?: LayoutConfig) {
    this.layout = layout || DEFAULT_LAYOUT;

    this.screen = blessed.screen({
      smartCSR: true,
      title: 'workspace-tui',
    });

    this.createPanels();
    this.setupKeybindings();
  }

  private createPanels(): void {
    for (const config of this.layout.panels) {
      const panel = this.createPanel(config);
      this.panels.set(config.id, panel);
    }
  }

  private createPanel(config: PanelConfig): CalendarPanel | EmailPanel | TasksPanel {
    const options: blessed.Widgets.BoxOptions = {
      border: 'line',
      style: {
        border: { fg: 'white' },
        focus: { border: { fg: 'green' } },
      },
    };

    switch (config.type) {
      case 'calendar':
        return new CalendarPanel(
          this.screen,
          config.row,
          config.col,
          config.rowSpan,
          config.colSpan,
          options
        );
      case 'email':
        return new EmailPanel(
          this.screen,
          config.row,
          config.col,
          config.rowSpan,
          config.colSpan,
          options
        );
      case 'tasks':
        return new TasksPanel(
          this.screen,
          config.row,
          config.col,
          config.rowSpan,
          config.colSpan,
          options
        );
    }
  }

  private setupKeybindings(): void {
    this.screen.key(['q', 'C-c'], () => {
      process.exit(0);
    });

    this.screen.key('Tab', () => {
      this.screen.focusNext();
    });

    this.screen.key('Shift-Tab', () => {
      this.screen.focusPrevious();
    });
  }

  async run(): Promise<void> {
    this.screen.render();
  }
}
