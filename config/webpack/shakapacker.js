import { loadShakapackerConfig } from "../shakapackerConfig.js";

export default loadShakapackerConfig(process.env.RAILS_ENV);
