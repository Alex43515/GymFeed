const modules = [
  "../src/config.mjs",
  "../src/contracts.mjs",
  "../src/prompts.mjs",
  "../src/repository.mjs",
  "../src/brain.mjs",
  "../src/orchestrator.mjs",
  "../src/app.mjs",
  "../src/providers/gemini.mjs",
  "../src/providers/byteplus.mjs",
  "../src/providers/blotato.mjs",
  "../src/render-carousel.mjs",
];

for (const module of modules) await import(module);
console.log(`Imported ${modules.length} modules successfully.`);
