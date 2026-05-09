/**
 * Google Tasks provider — fetches tasks and task lists from Google Tasks API.
 */
import type { OAuth2Client } from 'google-auth-library';
import { google, type tasks_v1 } from 'googleapis';
import type { PaginatedResult, Task, TaskList, TaskProvider } from '../../data/types.js';
import { paginate } from './helpers.js';

/** Google Tasks implementation */
export class GoogleTasks implements TaskProvider {
  constructor(private auth: OAuth2Client) {}

  /** Fetch all task lists */
  async getLists(): Promise<TaskList[]> {
    const tasks = google.tasks({ version: 'v1', auth: this.auth });
    const response = await tasks.tasklists.list();

    return (response.data.items || []).map((list) => ({
      id: list.id || '',
      name: list.title || '',
      provider: 'google' as const,
    }));
  }

  /** Fetch tasks with filtering, pagination, and sorting */
  async getTasks(query: {
    listIds?: string[];
    search?: string;
    done?: boolean;
    limit?: number;
    offset?: number;
    sortBy?: 'due' | 'title' | 'created';
    sortOrder?: 'asc' | 'desc';
  }): Promise<PaginatedResult<Task>> {
    const listIds = query.listIds?.length ? query.listIds : ['@default'];
    const allTasks: Task[] = [];

    for (const listId of listIds) {
      const tasks = await this.fetchTasksForList(listId, query.search, query.done);
      allTasks.push(...tasks);
    }

    this.sortTasks(allTasks, query.sortBy, query.sortOrder);
    return paginate(allTasks, query.offset || 0, query.limit || 50);
  }

  /** Fetch tasks from a specific task list with optional filtering */
  private async fetchTasksForList(
    listId: string,
    search?: string,
    done?: boolean
  ): Promise<Task[]> {
    const tasks = google.tasks({ version: 'v1', auth: this.auth });
    const response = await tasks.tasks.list({
      tasklist: listId,
      showCompleted: true,
      showDeleted: false,
      maxResults: 100,
    });

    const items = response.data.items || [];
    const subtaskMap = this.buildSubtaskMap(items);

    return items
      .filter((task) => !task.parent)
      .filter((task) => !search || task.title?.toLowerCase().includes(search.toLowerCase()))
      .filter((task) => done === undefined || (task.status === 'completed') === done)
      .map((task) => ({
        id: task.id || '',
        listId,
        listName: '',
        title: task.title || '',
        notes: task.notes || undefined,
        done: task.status === 'completed',
        due: task.due ? new Date(task.due) : undefined,
        subtasks: subtaskMap.get(task.id || '') || [],
        parentId: task.parent || undefined,
        provider: 'google' as const,
      }));
  }

  /** Build a map of parent task IDs to their subtasks */
  private buildSubtaskMap(items: tasks_v1.Schema$Task[]): Map<string, Task['subtasks']> {
    const map: Map<string, Task['subtasks']> = new Map();
    for (const item of items) {
      if (item.parent) {
        if (!map.has(item.parent)) map.set(item.parent, []);
        map.get(item.parent)?.push({
          id: item.id || '',
          title: item.title || '',
          done: item.status === 'completed',
        });
      }
    }
    return map;
  }

  /** Sort tasks by the specified field and order */
  private sortTasks(tasks: Task[], sortBy?: string, sortOrder?: string) {
    if (sortBy === 'title') {
      tasks.sort((a, b) =>
        sortOrder === 'desc' ? b.title.localeCompare(a.title) : a.title.localeCompare(b.title)
      );
    } else {
      tasks.sort((a, b) => this.compareDue(a, b, sortOrder));
    }
  }

  /** Compare two tasks by their due date for sorting */
  private compareDue(a: Task, b: Task, sortOrder?: string): number {
    if (!a.due && !b.due) return 0;
    if (!a.due) return sortOrder === 'desc' ? -1 : 1;
    if (!b.due) return sortOrder === 'desc' ? 1 : -1;
    return sortOrder === 'desc'
      ? b.due.getTime() - a.due.getTime()
      : a.due.getTime() - b.due.getTime();
  }
}
