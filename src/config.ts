/**
 * Configuration and vault management for workspace-tui.
 * Settings in .config/settings.json (committed).
 * Secrets in .config/vault.json (gitignored).
 */

import { existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

/** Provider credentials stored in vault */
export type Vault = {
  providers: {
    google?: {
      clientId: string;
      clientSecret: string;
      refreshToken: string;
    };
  };
};

function vaultPath() {
  return process.env.CONFIG_PATH || resolve(process.cwd(), '.config/vault.json');
}

/** Load vault (secrets) from .config/vault.json */
export function loadConfig(): Vault {
  try {
    const data = readFileSync(vaultPath(), 'utf-8');
    return JSON.parse(data);
  } catch {
    return { providers: {} };
  }
}

/** Save vault to .config/vault.json */
export function saveConfig(config: Vault): void {
  const path = vaultPath();
  const dir = dirname(path);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(path, JSON.stringify(config, null, 2));
}

/** Remove vault (logout) */
export function clearVault(): boolean {
  const path = vaultPath();
  if (existsSync(path)) {
    unlinkSync(path);
    return true;
  }
  return false;
}

/** Check if authenticated */
export function isAuthenticated(): boolean {
  const vault = loadConfig();
  return !!vault.providers.google?.refreshToken;
}
