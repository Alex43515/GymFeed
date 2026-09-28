import OpenAI from "openai";
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { loadConfig } from "../src/config.mjs";
import { MarketingBrain } from "../src/brain.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { appCaptureCatalog } from "../src/app-captures.mjs";
import { storyReviewPassed } from "../src/video-story.mjs";
import { generationPromptForContent, settleOrReleaseOpenAiReservation } from "../src/orchestrator.mjs";

// Deliberately isolated: one script call, one review, no campaign/media/Buffer methods.
const directory = resolve(process.argv[2] ?? "output/astra-story-pilot");
const resultPath = resolve(directory, "result.json");
const reviewExisting = process.argv.includes("--review-existing");
let existing;
await mkdir(directory, { recursive: true });
try {
  existing = JSON.parse(await readFile(resultPath, "utf8"));
  if (!reviewExisting) throw new Error(`Pilot already exists at ${resultPath}; refusing another paid attempt.`);
} catch (error) { if (error.code !== "ENOENT") throw error; }
if (reviewExisting && !existing?.script) throw new Error("An existing Astra script is required; no new script will be generated.");
const config = { ...loadConfig(), OPENAI_CREATIVE_MAX_OUTPUT_TOKENS: 9000 };
const brain = new MarketingBrain(config, new OpenAI({ apiKey: config.OPENAI_API_KEY, maxRetries: 0, timeout: 240000 }));
const repository = new MarketingRepository(config);
const { run, reused } = await repository.startRun("daily", "astra-story-pilot-2026-09-27-v1", { operation: "isolated-astra-script-test", creates_campaign: false });
if (reused && !reviewExisting) throw new Error(`Pilot run ${run.id} already exists (${run.status}); refusing a duplicate paid call.`);
const brief = "Write a 20-25 second English dialogue ad about two adult friends at the gym. One has arrived but is wasting time deciding what exercise to do; the other shows that their existing GymFeed Train routine is ready to start. Start with an original, concrete, mildly funny exchange rather than a product pitch. Distinct speakers, credible reply, real Train action, then a short human callback. Do NOT copy the ten-minutes/warmup joke from a previous discussion. Use 3 or 4 short native dialogue shots, at most one speaker per shot. Product proof can show opening an existing routine and Start workout, not the creation of a plan or completed exercise results. The verified train-start-track-complete-set source shows the routine in the opening frames and active workout by about 4 seconds; use only the opening 0-5 seconds for that proof. It contains a greeting and status bar: explicitly require privacy-safe crop/masking and visual verification before a real render. Do not imply a whole workout was completed in seconds. Select a genuine still only if needed for CTA. Include no performance statistics or research evidence IDs.";
let reservation;
let total = existing?.total_cost_usd ?? 0;
let script = existing?.script;
let review;
try {
  if (!reviewExisting) {
  reservation = await repository.reserveCost("openai", 1, { runId: run.id, metadata: { operation: "astra-story-pilot", max_output_tokens: 9000, model: "gpt-6-astra" } });
  script = await brain.draftVideo(brief, { model: "gpt-6-astra", appCaptures: (await appCaptureCatalog()).filter((item) => item.id === "requested:train-start-track-complete-set") });
  await repository.settleCost(reservation, script.costUsd, script.responseId);
  reservation = null;
  total += script.costUsd;
  await writeFile(resultPath, JSON.stringify({ status: "script_created", ...script }, null, 2));
  }
  reservation = await repository.reserveCost("openai", 0.05, { runId: run.id, metadata: { operation: "astra-story-pilot-review", model: config.OPENAI_QA_MODEL } });
  review = await brain.storyQualityReview(script.data);
  await repository.settleCost(reservation, review.costUsd, review.responseId);
  reservation = null;
  total += review.costUsd;
  const passed = storyReviewPassed(review.data);
  const previousReviewReport = reviewExisting ? await readFile(resolve(directory, "pilot.md"), "utf8") : undefined;
  await writeFile(resultPath, JSON.stringify({ status: passed ? "script_review_passed" : "script_needs_revision", script, review, previous_review_report: previousReviewReport, total_cost_usd: total, media_generated: false, published: false }, null, 2));
  const lines = ["# GymFeed Astra Story Pilot", "", `Model: ${script.model}`, `Script + independent review: $${total.toFixed(6)}`, `Creative gate: ${passed ? "PASS" : "NEEDS REVISION"}`, "No media was generated or published. This is one script test, not a comparative quality benchmark.", "", `## ${script.data.review_brief.title}`, "", script.data.concept, "", ...script.data.scenes.map((scene) => `- ${scene.scene_id} (${scene.duration_seconds}s; ${scene.asset_type}): ${scene.speaker_id || "Narrator"}: ${scene.spoken_dialogue || scene.voiceover_text || scene.overlay_text}\n  Visual: ${scene.action}`), "", "## Independent Review", review.data.summary, ...review.data.required_fixes.map((fix) => `- ${fix}`), "", "## Production Prompts", "", generationPromptForContent({ content_type: "video", decision: { content: script.data } })];
  await writeFile(resolve(directory, "pilot.md"), lines.join("\n"));
  await repository.finishRun(run.id, "succeeded", { operation: "isolated-astra-script-test", creative_gate_passed: passed, result_path: resultPath, media_generated: false }, total);
  console.log(JSON.stringify({ resultPath, model: script.model, costUsd: total, passed, review: review.data, title: script.data.review_brief.title }));
} catch (error) {
  await settleOrReleaseOpenAiReservation(repository, reservation, error);
  total += error.openaiCostUsd ?? 0;
  await repository.finishRun(run.id, "failed", { operation: "isolated-astra-script-test", media_generated: false }, total, error.message);
  await writeFile(resultPath, JSON.stringify({ status: "failed", error: error.message, script, review, total_cost_usd: total }, null, 2));
  throw error;
}
