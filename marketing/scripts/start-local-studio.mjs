import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
const root = fileURLToPath(new URL("../", import.meta.url));
process.chdir(root);
process.loadEnvFile(new URL("../.env", import.meta.url));
const credentials = fileURLToPath(new URL("../secrets/ga4-service-account.json", import.meta.url));
if (existsSync(credentials)) {
  process.env.GOOGLE_SHEETS_CREDENTIALS = credentials;
  process.env.GOOGLE_APPLICATION_CREDENTIALS = credentials;
}
process.env.PORT = "3000";
process.env.STUDIO_SCHEDULER = "local_worker";
process.env.LOG_LEVEL = "warn";
await import("../src/server.mjs");
