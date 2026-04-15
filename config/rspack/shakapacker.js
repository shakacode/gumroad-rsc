import { getConfigEnvironment } from "./environment.js";
import { loadShakapackerConfig } from "../shakapackerConfig.js";

export default loadShakapackerConfig(getConfigEnvironment());
