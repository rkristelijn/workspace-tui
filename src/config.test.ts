import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { loadConfig, saveConfig } from './config.js';

const TEST_DIR = '/tmp/workspace-tui-test';
const TEST_CONFIG = `${TEST_DIR}/config.json`;

describe('config', () => {
  beforeEach(() => {
    process.env.CONFIG_PATH = TEST_CONFIG;
    if (existsSync(TEST_DIR)) rmSync(TEST_DIR, { recursive: true });
  });

  afterEach(() => {
    delete process.env.CONFIG_PATH;
    if (existsSync(TEST_DIR)) rmSync(TEST_DIR, { recursive: true });
  });

  describe('loadConfig', () => {
    it('returns empty config when file does not exist', () => {
      const config = loadConfig();
      expect(config).toEqual({ providers: {} });
    });

    it('loads config from disk', () => {
      mkdirSync(TEST_DIR, { recursive: true });
      writeFileSync(
        TEST_CONFIG,
        JSON.stringify({
          providers: { google: { clientId: 'x', clientSecret: 'y', refreshToken: 'z' } },
        })
      );

      const config = loadConfig();
      expect(config.providers.google?.clientId).toBe('x');
    });
  });

  describe('saveConfig', () => {
    it('creates directory and writes config', () => {
      saveConfig({
        providers: { google: { clientId: 'a', clientSecret: 'b', refreshToken: 'c' } },
      });

      const data = JSON.parse(readFileSync(TEST_CONFIG, 'utf-8'));
      expect(data.providers.google.clientId).toBe('a');
    });

    it('overwrites existing config', () => {
      mkdirSync(TEST_DIR, { recursive: true });
      writeFileSync(TEST_CONFIG, '{}');

      saveConfig({
        providers: { google: { clientId: 'new', clientSecret: 's', refreshToken: 'r' } },
      });

      const data = JSON.parse(readFileSync(TEST_CONFIG, 'utf-8'));
      expect(data.providers.google.clientId).toBe('new');
    });
  });
});
