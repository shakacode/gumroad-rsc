import * as rspack from "@rspack/core";
import fs from "fs";
import { fileURLToPath } from "node:url";
import path from "path";
import { RspackManifestPlugin } from "rspack-manifest-plugin";
import tsCast from "ts-safe-cast/transformer.js";
import { BundleAnalyzerPlugin } from "webpack-bundle-analyzer";

import shakapackerConfig from "./shakapacker.js";

const dirname = path.dirname(fileURLToPath(import.meta.url));
const rootPath = path.join(dirname, "../../");
const sourcePath = path.join(rootPath, shakapackerConfig.source_path);
const context = path.join(sourcePath, shakapackerConfig.source_entry_path);
const additionalPaths = shakapackerConfig.additional_paths.map((dir) => path.join(rootPath, dir));
const outputPath = path.join(rootPath, shakapackerConfig.public_root_path, shakapackerConfig.public_output_path);
const assetHost = process.env.SHAKAPACKER_ASSET_HOST || "/";
const publicOutputPath = `${assetHost.endsWith("/") ? assetHost : `${assetHost}/`}${shakapackerConfig.public_output_path}/`;
const nodeEnv = process.env.NODE_ENV || process.env.RAILS_ENV || "development";
const isProduction = nodeEnv === "production";
const hash = isProduction ? "-[contenthash]" : "";
const miniCssHash = isProduction ? "-[contenthash:8]" : "";
const mode = isProduction ? "production" : "development";
const manifestSeed = {};
const widgetRoot = path.join(sourcePath, "widget");
const excludedMainEntries = new Set([
  "dashboard_rsc_demo",
  "server-bundle",
  "rsc-bundle",
  "dashboard_rsc_demo_server_entry",
]);
const transpileNodeModulesPackages = [`${path.sep}node_modules${path.sep}ts-safe-cast${path.sep}`];
const shouldExcludeFromTranspile = (resourcePath) =>
  resourcePath.includes(`${path.sep}node_modules${path.sep}`) &&
  !transpileNodeModulesPackages.some((packagePath) => resourcePath.includes(packagePath));

const styleLoaders = [
  rspack.CssExtractRspackPlugin.loader,
  {
    loader: "css-loader",
    options: {
      sourceMap: true,
      importLoaders: 2,
    },
  },
  {
    loader: "postcss-loader",
    options: { sourceMap: true },
  },
];

const javascriptRule = {
  test: /\.(js|mjs)$/u,
  exclude: shouldExcludeFromTranspile,
  type: "javascript/auto",
  use: [
    {
      loader: "builtin:swc-loader",
      options: {
        jsc: {
          target: "es2019",
          parser: {
            syntax: "ecmascript",
            jsx: true,
          },
          transform: {
            react: {
              runtime: "automatic",
            },
          },
        },
      },
    },
  ],
};

const typescriptRule = {
  test: /\.(ts|tsx)$/u,
  exclude: shouldExcludeFromTranspile,
  type: "javascript/auto",
  use: [
    {
      loader: "builtin:swc-loader",
      options: {
        jsc: {
          target: "es2019",
          parser: {
            syntax: "typescript",
            tsx: true,
          },
          transform: {
            react: {
              runtime: "automatic",
            },
          },
        },
      },
    },
    {
      loader: path.join(dirname, "../webpack/loaders/transformerLoader.js"),
      options: { getTransformers: (program) => [tsCast(program)] },
    },
  ],
};

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
  exclude: /app\/assets\/images\/email/u,
  type: "asset",
  generator: { filename: "static/[hash][ext][query]" },
};

const sassRule = {
  test: /\.scss$/iu,
  use: [
    ...styleLoaders,
    {
      loader: "sass-loader",
      options: {
        sassOptions: { includePaths: additionalPaths },
      },
    },
  ],
};

const createManifestPlugin = () =>
  new RspackManifestPlugin({
    fileName: "manifest.json",
    publicPath: publicOutputPath,
    seed: manifestSeed,
    writeToFileEmit: true,
    generate: (seed, files, entrypoints) => {
      files.forEach((file) => {
        seed[file.name] = file.path;
      });

      seed.entrypoints = {
        ...(seed.entrypoints || {}),
        ...Object.fromEntries(
          Object.entries(entrypoints).map(([entrypointName, entrypointFiles]) => {
            const js = entrypointFiles
              .filter((file) => file.endsWith(".js") && !file.includes(".hot-update."))
              .map((file) => `${publicOutputPath}${file}`);
            const css = entrypointFiles
              .filter((file) => file.endsWith(".css") && !file.includes(".hot-update."))
              .map((file) => `${publicOutputPath}${file}`);

            return [entrypointName, { assets: { js, css } }];
          }),
        ),
      };

      return seed;
    },
  });

const createCssExtractPlugin = () =>
  new rspack.CssExtractRspackPlugin({
    filename: `css/[name]${miniCssHash}.css`,
    chunkFilename: `css/[id]${miniCssHash}.css`,
    ignoreOrder: shakapackerConfig.css_extract_ignore_order_warnings,
    emit: true,
  });

const baseOutput = {
  globalObject: "globalThis",
  path: outputPath,
  filename: `js/[name]${hash}.js`,
  chunkFilename: `js/[name]${hash}.chunk.js`,
  hotUpdateChunkFilename: "js/[id].[fullhash].hot-update.js",
  publicPath: publicOutputPath,
};

const mainEntry = {};
for (const file of fs.readdirSync(context)) {
  if (file.startsWith(".")) continue;
  const entryName = path.parse(file).name;
  if (excludedMainEntries.has(entryName)) continue;
  (mainEntry[entryName] ??= []).push(`./${file}`);
}

const mainConfig = {
  mode,
  devtool: "cheap-module-source-map",
  context,
  entry: mainEntry,
  resolve: {
    extensions: [".js", ".ts", ".tsx"],
    modules: [...additionalPaths, "node_modules"],
    alias: {
      jwplayer: path.join(rootPath, "vendor/assets/components/jwplayer-7.12.13/jwplayer"),
      $vendor: path.join(rootPath, "vendor/assets/javascripts"),
      $app: path.join(rootPath, "app/javascript"),
      $assets: path.join(rootPath, "app/assets"),
    },
  },
  optimization: {
    runtimeChunk: {
      name: "webpack-runtime",
    },
    splitChunks: {
      chunks: "all",
      cacheGroups: {
        commons: {
          name: "webpack-commons",
          chunks: "initial",
          minChunks: 3,
        },
      },
    },
  },
  module: {
    rules: [
      sassRule,
      assetRule,
      javascriptRule,
      typescriptRule,
      {
        resourceQuery: /resource/u,
        type: "asset/resource",
      },
      {
        test: [/\.html$/u],
        type: "asset/source",
      },
      {
        test: /\.(css)$/iu,
        use: styleLoaders,
      },
    ],
  },
  plugins: [
    createManifestPlugin(),
    createCssExtractPlugin(),
    new rspack.ProvidePlugin({ Routes: "$app/utils/routes" }),
    process.env.WEBPACK_ANALYZE === "1" && new BundleAnalyzerPlugin(),
    new rspack.DefinePlugin({ SSR: false }),
  ].filter(Boolean),
  output: baseOutput,
};

const widgetConfig = {
  mode,
  context: widgetRoot,
  entry: {
    embed: "./embed.ts",
    overlay: ["./overlay.ts", "./overlay.scss"],
  },
  resolve: {
    extensions: [".js", ".ts"],
    modules: [...additionalPaths, "node_modules"],
  },
  output: baseOutput,
  module: {
    rules: [sassRule, assetRule, javascriptRule, typescriptRule],
  },
  plugins: [
    createManifestPlugin(),
    createCssExtractPlugin(),
    new rspack.EnvironmentPlugin(["ROOT_DOMAIN", "SHORT_DOMAIN", "DOMAIN", "PROTOCOL"]),
  ],
};

export default [mainConfig, widgetConfig];
