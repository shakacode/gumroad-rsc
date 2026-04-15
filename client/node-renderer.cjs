const path = require("path");
const { reactOnRailsProNodeRenderer, parseWorkersCount } = require("react-on-rails-pro-node-renderer");

const { env } = process;
const configuredWorkersCount =
  parseWorkersCount(env.RENDERER_WORKERS_COUNT) ?? parseWorkersCount(env.NODE_RENDERER_CONCURRENCY);

const config = {
  serverBundleCachePath: path.resolve(__dirname, "../.node-renderer-bundles"),
  port: Number(env.RENDERER_PORT) || 3800,
  logLevel: env.RENDERER_LOG_LEVEL || "info",
  password: env.RENDERER_PASSWORD || "devPassword",
  workersCount: configuredWorkersCount ?? 3,
  supportModules: true,
  additionalContext: { URL, AbortController },
  stubTimers: false,
  replayServerAsyncOperationLogs: true,
};

if (env.CI && configuredWorkersCount == null) {
  config.workersCount = 2;
}

reactOnRailsProNodeRenderer(config);
