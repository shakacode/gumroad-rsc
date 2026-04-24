import fs from "fs";
import yaml from "js-yaml";
import { fileURLToPath } from "node:url";

const DEV_SERVER_ENV_PREFIX = "SHAKAPACKER_DEV_SERVER";
const BOOLEAN_VALUES = new Set(["true", "false"]);

const parseEnvValue = (value) => {
  if (BOOLEAN_VALUES.has(value)) return value === "true";
  if (/^-?\d+$/u.test(value)) return Number(value);
  return value;
};

const applyDevServerEnvOverrides = (config) => {
  if (!config?.dev_server) return config;

  const devServer = { ...config.dev_server };
  const envPrefix = devServer.env_prefix || DEV_SERVER_ENV_PREFIX;

  for (const key of Object.keys(devServer)) {
    const envValue = process.env[`${envPrefix}_${key.toUpperCase()}`];
    if (envValue === undefined) continue;

    if (key === "server" && typeof devServer.server === "object" && devServer.server !== null) {
      devServer.server = {
        ...devServer.server,
        type: parseEnvValue(envValue),
      };
      continue;
    }

    devServer[key] = parseEnvValue(envValue);
  }

  return {
    ...config,
    dev_server: devServer,
  };
};

export const loadShakapackerConfig = (environment) =>
  applyDevServerEnvOverrides(
    yaml.load(fs.readFileSync(fileURLToPath(import.meta.resolve("./shakapacker.yml"))))[environment],
  );
