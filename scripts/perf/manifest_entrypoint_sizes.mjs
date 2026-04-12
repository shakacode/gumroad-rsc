import fs from "fs";
import path from "path";

const manifestPath = process.argv[2] ? path.resolve(process.argv[2]) : path.resolve("public/packs/manifest.json");
const rootDir = path.dirname(manifestPath);
const entrypointName = process.argv[3] || "inertia";

const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const entrypoint = manifest.entrypoints?.[entrypointName]?.assets;

if (!entrypoint) {
  console.error(`Entrypoint '${entrypointName}' not found in ${manifestPath}`);
  process.exit(1);
}

const statForAsset = (assetPath) => {
  const relativePath = assetPath.replace(/^\/packs\//, "");
  const absolutePath = path.join(rootDir, relativePath);
  const stats = fs.statSync(absolutePath);
  return {
    asset: assetPath,
    bytes: stats.size,
  };
};

const js = (entrypoint.js || []).map(statForAsset);
const css = (entrypoint.css || []).map(statForAsset);

const summarize = (assets) => ({
  count: assets.length,
  totalBytes: assets.reduce((sum, asset) => sum + asset.bytes, 0),
  assets,
});

const result = {
  manifestPath,
  entrypointName,
  js: summarize(js),
  css: summarize(css),
  totalBytes: [...js, ...css].reduce((sum, asset) => sum + asset.bytes, 0),
};

console.log(JSON.stringify(result, null, 2));
