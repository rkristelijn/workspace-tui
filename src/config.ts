export type Config = {
  providers: {
    google?: {
      clientId: string;
      clientSecret: string;
      refreshToken: string;
    };
  };
};

export function loadConfig(): Config {
  const configPath = process.env.CONFIG_PATH || `${process.env.HOME}/.workspace-tui/config.json`;

  try {
    const fs = require('node:fs');
    const data = fs.readFileSync(configPath, 'utf-8');
    return JSON.parse(data);
  } catch {
    return { providers: {} };
  }
}

export function saveConfig(config: Config): void {
  const configPath = process.env.CONFIG_PATH || `${process.env.HOME}/.workspace-tui/config.json`;
  const fs = require('node:fs');
  const path = require('node:path');

  const dir = path.dirname(configPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
}
