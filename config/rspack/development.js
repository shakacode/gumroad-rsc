import { merge } from "webpack-merge";

import configs from "./common.js";
import shakapacker from "./shakapacker.js";

const { dev_server } = shakapacker;

export default configs.map((config, idx) =>
  merge(config, {
    stats: {
      colors: true,
      entrypoints: false,
      errorDetails: true,
      modules: false,
      moduleTrace: false,
    },
    devServer:
      dev_server && process.env.WEBPACK_SERVE === "true" && idx === 0
        ? {
            compress: dev_server.compress,
            allowedHosts: dev_server.allowed_hosts,
            host: process.env.SHAKAPACKER_DEV_SERVER_HOST || dev_server.host,
            port: dev_server.port,
            server: dev_server.server,
            hot: dev_server.hmr,
            liveReload: !dev_server.hmr,
            historyApiFallback: { disableDotRule: true },
            headers: dev_server.headers,
            client: dev_server.client,
            devMiddleware: { writeToDisk: true },
            static: {
              directory: config.output.path,
              ...dev_server.static,
            },
          }
        : undefined,
  }),
);
