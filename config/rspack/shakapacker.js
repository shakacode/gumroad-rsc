import fs from "fs";
import yaml from "js-yaml";
import { fileURLToPath } from "node:url";

const getEnvironment = () => {
  if (process.env.RAILS_ENV) return process.env.RAILS_ENV;
  if (process.env.NODE_ENV === "test") return "test";
  if (process.env.NODE_ENV === "production") return "production";
  return "development";
};

export default yaml.load(fs.readFileSync(fileURLToPath(import.meta.resolve("../shakapacker.yml"))))[getEnvironment()];
