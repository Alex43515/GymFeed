import { execFileSync, spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { existsSync } from "node:fs";
const deploy = fileURLToPath(new URL("../deploy/", import.meta.url));
const dashboard = fileURLToPath(new URL("../dashboard/", import.meta.url));
try {
  execFileSync("docker", ["compose", "--env-file", "../.env", "up", "-d", "postgres", "n8n", "marketing-worker"], { cwd: deploy, stdio: "inherit" });
} catch {
  console.error("Start Docker Desktop, then run npm run studio again.");
  process.exit(1);
}
const next = fileURLToPath(new URL("../dashboard/node_modules/next/dist/bin/next", import.meta.url));
if (!existsSync(next)) {
  console.error(`Install the dashboard dependencies first: cd "${dashboard}" && npm ci`);
  process.exit(1);
}
const alreadyRunning = await fetch("http://127.0.0.1:3100", { signal: AbortSignal.timeout(2000) }).then(r => r.ok).catch(() => false);
if (alreadyRunning) {
  console.log("Marketing Studio is ready: http://127.0.0.1:3100");
} else {
  const child = spawn(process.execPath, [next, "dev", "--hostname", "127.0.0.1", "--port", "3100"], { cwd: dashboard, stdio: "inherit" });
  for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => child.kill(signal));
  child.once("exit", code => process.exit(code ?? 0));
}
