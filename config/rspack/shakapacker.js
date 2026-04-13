import fs from "fs";
import yaml from "js-yaml";
import { fileURLToPath } from "node:url";
import getEnvironment from "./environment.js";

export default yaml.load(fs.readFileSync(fileURLToPath(import.meta.resolve("../shakapacker.yml"))))[getEnvironment()];
