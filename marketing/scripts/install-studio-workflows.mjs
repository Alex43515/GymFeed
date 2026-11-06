import { execFileSync } from "node:child_process";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { fileURLToPath } from "node:url";
const root = fileURLToPath(new URL("../", import.meta.url));
const runtime = new URL("../.dashboard-runtime/", import.meta.url);
await mkdir(runtime, { recursive: true });
const docker = (...args) => execFileSync("docker", args, { encoding: "utf8", cwd: root });
const container = "gymfeed-marketing-n8n-1";
// Export the live versions, not repository copies: preserve local n8n edits.
docker("exec", container, "n8n", "export:workflow", "--all", "--output=/tmp/studio-before.json");
const backupPath = fileURLToPath(new URL(`n8n-before-${Date.now()}.json`, runtime));
docker("cp", `${container}:/tmp/studio-before.json`, backupPath);
const live = JSON.parse(await readFile(backupPath, "utf8"));
const dispatcher = JSON.parse(await readFile(new URL("../deploy/workflows/08-studio-job-dispatcher.json", import.meta.url), "utf8"));
const handler = JSON.parse(await readFile(new URL("../deploy/workflows/09-studio-error-handler.json", import.meta.url), "utf8"));
const ids = new Set([dispatcher.id, handler.id]);
const updated = live.filter(w => !ids.has(w.id)).map(w => w.name.startsWith("GymFeed")
  ? { ...w, settings: { ...w.settings, errorWorkflow: handler.id } } : w);
updated.push({ ...handler, active: false }, { ...dispatcher, active: true });
const inputPath = fileURLToPath(new URL("n8n-studio-install.json", runtime));
await writeFile(inputPath, JSON.stringify(updated));
docker("cp", inputPath, `${container}:/tmp/studio-install.json`);
console.log(docker("exec", container, "n8n", "import:workflow", "--input=/tmp/studio-install.json"));
for (const workflow of updated.filter(w => w.active)) {
  docker("exec", container, "n8n", "publish:workflow", `--id=${workflow.id}`);
  console.log(`Published: ${workflow.name}`);
}
console.log(JSON.stringify({ installed: [dispatcher.id, handler.id], previousWorkflowsPreserved: live.length, backupPath }));
