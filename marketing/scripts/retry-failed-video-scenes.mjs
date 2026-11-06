import { loadConfig } from "../src/config.mjs";
import { MarketingRepository } from "../src/repository.mjs";
import { MarketingCampaigns } from "../src/campaigns.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { FalMediaProvider } from "../src/providers/fal.mjs";

// Explicit operator action: retain saved media and retry only failed submissions.
const contentId = process.argv[2];
if (!contentId) throw new Error("Supply the approved video content ID");
const config = loadConfig();
const repository = new MarketingRepository(config);
const campaigns = new MarketingCampaigns({ repository });
const mediaProvider = new FalMediaProvider({ apiKey: config.FAL_KEY,
  videoModel: config.FAL_VIDEO_MODEL, referenceVideoModel: config.FAL_REFERENCE_VIDEO_MODEL,
  videoResolution: config.FAL_VIDEO_RESOLUTION });
const orchestrator = new MarketingOrchestrator({ config, repository, campaigns, mediaProvider });
const queued = await campaigns.withWork(contentId, "generate", async () => {
  let content = await repository.contentById(contentId);
  if (content.content_type !== "video" || content.status !== "failed") {
    throw new Error(`Expected a failed video; got ${content.content_type}/${content.status}`);
  }
  const generation = structuredClone(content.decision.generation);
  const failed = generation?.scenes?.filter(s => s.asset_type === "generated_video" && s.status === "failed");
  if (!failed?.length) throw new Error("No failed scenes to retry");
  if (failed.some(s => s.asset_url)) throw new Error("Failed scene has existing media; inspect before retrying");
  const plan = content.decision.content;
  for (const previous of failed) {
    const scene = plan.scenes.find(s => s.scene_id === previous.scene_id);
    if (!scene) throw new Error(`Missing approved scene ${previous.scene_id}`);
    if (Number(previous.attempt) >= config.FAL_SCENE_MAX_ATTEMPTS) throw new Error(`Attempt limit: ${previous.scene_id}`);
    const retry = await orchestrator.queueVideoScene(content, scene,
      plan.cast?.length ? generation.character_reference_urls : generation.reference_image_url,
      Number(previous.attempt ?? 0) + 1);
    const { history = [], ...previousAttempt } = previous;
    generation.scenes[generation.scenes.findIndex(s => s.scene_id === previous.scene_id)] = {
      ...retry, edit_attempts: previous.edit_attempts ?? 0, history: [...history, previousAttempt],
    };
    // Persist every accepted task before submitting another chargeable request.
    content = await repository.updateContent(contentId, {
      provider: "fal-reference+gymfeed-edit",
      provider_task_id: generation.scenes.find(s => s.status === "queued")?.task_id ?? null,
      decision: { ...content.decision, generation },
    });
    console.log(JSON.stringify({ scene: scene.scene_id, taskId: retry.task_id, model: retry.model, status: retry.status }));
  }
  content = await repository.updateContent(contentId, {
    status: "generating", failure_reason: null,
    decision: { ...content.decision, generation,
      campaign: { ...content.decision.campaign, production_blocked: false,
        production_block_reason: null, production_block_kind: null },
      workflow: { ...content.decision.workflow, stage: "generating",
        message: `Retry started: ${failed.length} failed scenes; existing media retained.`, at: new Date().toISOString() },
    },
  });
  return { queued: failed.length, status: content.status };
});
console.log(JSON.stringify({ phase: "queued", ...queued }));
if (queued.skipped) throw new Error(`Work claim unavailable: ${queued.reason}`);
const response = await fetch(`http://127.0.0.1:${config.PORT}/v1/content/${contentId}/process`, {
  method: "POST", headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN, "content-type": "application/json" },
  body: "{}", signal: AbortSignal.timeout(25 * 60_000),
});
const result = await response.json();
if (!response.ok) throw new Error(result.message ?? `Processing HTTP ${response.status}`);
console.log(JSON.stringify({ phase: "process", status: result.content?.status, pending: result.pending, reason: result.reason }));
const content = await repository.contentById(contentId);
const sync = await fetch(`http://127.0.0.1:${config.PORT}/v1/cmo/execute`, {
  method: "POST", headers: { "x-marketing-token": config.MARKETING_INTERNAL_TOKEN, "content-type": "application/json" },
  body: JSON.stringify({ action: "sync", campaignId: content.decision.campaign.id }),
});
if (!sync.ok) throw new Error(`Sheet sync HTTP ${sync.status}`);
console.log(JSON.stringify({ phase: "finished", status: content.status, sheetSynced: true }));
