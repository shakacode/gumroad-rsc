const path = require("path");
const webpack = require("webpack");
const { RSCWebpackPlugin } = require("react-on-rails-rsc/WebpackPlugin");

const rootPath = path.resolve(__dirname, "../..");
const sourcePath = path.join(rootPath, "app/javascript");
const packsPath = path.join(sourcePath, "packs");
const privateOutputPath = path.join(rootPath, "ssr-generated");
const buildEnvironment = (() => {
  if (process.env.NODE_ENV) return process.env.NODE_ENV;
  if (process.env.RAILS_ENV === "test") return "test";
  if (process.env.RAILS_ENV === "production" || process.env.RAILS_ENV === "staging") return "production";
  return process.env.RAILS_ENV || "development";
})();
const publicOutputDirectory = buildEnvironment === "test" ? "public/packs-test" : "public/packs";
const publicOutputPath = path.join(rootPath, publicOutputDirectory);
const mode = buildEnvironment === "production" ? "production" : "development";
const rscClientReferencesDirectory = path.relative(
  packsPath,
  path.join(sourcePath, "src/dashboard_rsc_demo/ror_components"),
);

const baseResolve = {
  extensions: [".js", ".mjs", ".ts", ".tsx", ".json"],
  modules: [sourcePath, path.join(rootPath, "app/assets"), "node_modules"],
  alias: {
    jwplayer: path.join(rootPath, "vendor/assets/components/jwplayer-7.12.13/jwplayer"),
    $vendor: path.join(rootPath, "vendor/assets/javascripts"),
    $app: sourcePath,
    $assets: path.join(rootPath, "app/assets"),
  },
};

const createEsbuildUse = (loader, rscBundle = false) => [
  {
    loader: "esbuild-loader",
    options: {
      loader,
      target: "es2019",
    },
  },
  ...(rscBundle ? [{ loader: "react-on-rails-rsc/WebpackLoader" }] : []),
];

const createScriptRules = (rscBundle = false) => [
  {
    test: /\.tsx$/u,
    exclude: /node_modules\/(?!ts-safe-cast)/u,
    use: createEsbuildUse("tsx", rscBundle),
  },
  {
    test: /\.ts$/u,
    exclude: /node_modules\/(?!ts-safe-cast)/u,
    use: createEsbuildUse("ts", rscBundle),
  },
  {
    test: /\.(js|mjs)$/u,
    exclude: /node_modules\/(?!ts-safe-cast)/u,
    use: createEsbuildUse("jsx", rscBundle),
  },
];

const assetRule = {
  test: [
    /\.bmp$/u,
    /\.gif$/u,
    /\.jpe?g$/u,
    /\.png$/u,
    /\.tiff$/u,
    /\.ico$/u,
    /\.avif$/u,
    /\.webp$/u,
    /\.eot$/u,
    /\.otf$/u,
    /\.ttf$/u,
    /\.woff2?$/u,
    /\.svg$/u,
  ],
  type: "asset",
  generator: { filename: "static/[hash][ext][query]" },
};

const basePlugins = (ssr) => [
  new webpack.ProvidePlugin({ Routes: path.join(sourcePath, "utils/routes.js") }),
  new webpack.DefinePlugin({ SSR: JSON.stringify(ssr) }),
];

const rscWebpackPluginOptions = (isServer) => ({
  isServer,
  clientReferences: [
    {
      directory: rscClientReferencesDirectory,
      recursive: true,
      include: /\.(js|ts|jsx|tsx)$/u,
    },
  ],
});

const clientConfig = {
  name: "dashboard-rsc-demo-client",
  mode,
  devtool: mode === "production" ? "nosources-source-map" : "cheap-module-source-map",
  context: packsPath,
  entry: {
    dashboard_rsc_demo: "./dashboard_rsc_demo.tsx",
  },
  resolve: baseResolve,
  module: {
    rules: [assetRule, ...createScriptRules(false)],
  },
  plugins: [...basePlugins(false), new RSCWebpackPlugin(rscWebpackPluginOptions(false))],
  output: {
    filename: "[name].js",
    path: publicOutputPath,
    publicPath: buildEnvironment === "test" ? "/packs-test/" : "/packs/",
  },
};

const serverConfig = {
  name: "dashboard-rsc-demo-server",
  mode,
  devtool: "eval",
  context: packsPath,
  entry: {
    "server-bundle": "./dashboard_rsc_demo_server_entry.tsx",
  },
  resolve: baseResolve,
  target: "node",
  module: {
    rules: [assetRule, ...createScriptRules(false)],
  },
  optimization: {
    minimize: false,
  },
  plugins: [
    ...basePlugins(true),
    new RSCWebpackPlugin(rscWebpackPluginOptions(true)),
    new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 }),
  ],
  output: {
    filename: "server-bundle.js",
    globalObject: "this",
    libraryTarget: "commonjs2",
    path: privateOutputPath,
  },
};

const rscConfig = {
  name: "dashboard-rsc-demo-rsc",
  mode,
  devtool: "eval",
  context: packsPath,
  entry: {
    "rsc-bundle": "./dashboard_rsc_demo_server_entry.tsx",
  },
  resolve: {
    ...baseResolve,
    conditionNames: ["react-server", "..."],
    alias: {
      ...baseResolve.alias,
      "react-dom/server": false,
    },
  },
  target: "node",
  module: {
    rules: [assetRule, ...createScriptRules(true)],
  },
  optimization: {
    minimize: false,
  },
  plugins: [...basePlugins(true), new webpack.optimize.LimitChunkCountPlugin({ maxChunks: 1 })],
  output: {
    filename: "rsc-bundle.js",
    globalObject: "this",
    libraryTarget: "commonjs2",
    path: privateOutputPath,
  },
};

module.exports = [clientConfig, serverConfig, rscConfig];
