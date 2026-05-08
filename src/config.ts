/**
 * Configuration management for workspace-tui
 * Stores OAuth credentials in ~/.workspace-tui/config.json
 */

import * as fs from 'node:fs';
import * as path from 'node:path';

/**
 * Application configuration structure
 * Contains provider-specific credentials
 */
export type Config = {
  providers: {
    /** Google Workspace OAuth credentials */
    google?: {
      /** OAuth 2.0 Client ID */
      clientId: string;
      /** OAuth 2.0 Client Secret */
      clientSecret: string;
      /** OAuth 2.0 Refresh Token for persistent access */
      refreshToken: string;
    };
  };
};

/**
 * Load configuration from disk
 * @returns Configuration object, or empty config if file doesn't exist
 */
export function loadConfig(): Config {
  const configPath = process.env.CONFIG_PATH || `${process.env.HOME}/.workspace-tui/config.json`;

  try {
    const data = fs.readFileSync(configPath, 'utf-8');
    return JSON.parse(data);
  } catch {
    return { providers: {} };
  }
}

/**
 * Save configuration to disk
 * Creates directory if it doesn't exist
 */
export function saveConfig(config: Config): void {
  const configPath = process.env.CONFIG_PATH || `${process.env.HOME}/.workspace-tui/config.json`;

  const dir = path.dirname(configPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}
