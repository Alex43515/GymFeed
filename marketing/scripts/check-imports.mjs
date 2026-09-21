const modules = [
  "../src/config.mjs",
  "../src/contracts.mjs",
  "../src/prompts.mjs",
  "../src/repository.mjs",
  "../src/brain.mjs",
  "../src/orchestrator.mjs",
  "../src/campaigns.mjs",
  "../src/cmo-controller.mjs",
  "../src/app-captures.mjs",
  "../src/campaign-schedule.mjs",
  "../src/app.mjs",
  "../src/providers/fal.mjs",
  "../src/providers/buffer.mjs",
  "../src/providers/openai-voice.mjs",
  "../src/providers/google-sheets.mjs",
  "../src/extract-video-frame.mjs",
  "../src/render-carousel.mjs",
];

for (const module of modules) await import(module);
console.log(`Imported ${modules.length} modules successfully.`);
