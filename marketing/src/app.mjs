import Fastify from "fastify";

function tokenFrom(request, name) {
  const value = request.headers[name];
  return Array.isArray(value) ? value[0] : value;
}

export function buildApp({ config, orchestrator, logger = true }) {
  const app = Fastify({ logger });

  app.addHook("onRequest", async (request, reply) => {
    if (!request.url.startsWith("/v1/")) return;
    const isApproval = /^\/v1\/content\/[^/]+\/approve(?:\?|$)/.test(request.url);
    const expected = isApproval ? config.MARKETING_APPROVAL_TOKEN : config.MARKETING_INTERNAL_TOKEN;
    const header = isApproval ? "x-marketing-approval-token" : "x-marketing-token";
    if (tokenFrom(request, header) !== expected) return reply.code(401).send({ error: "unauthorized" });
  });

  app.get("/health", async () => ({ ok: true, service: "gymfeed-marketing-worker" }));
  app.post("/v1/runs/daily", async () => orchestrator.runDaily());
  app.post("/v1/runs/weekly", async () => orchestrator.runWeekly());
  app.post("/v1/runs/pipeline", async () => orchestrator.runPipeline());
  app.post("/v1/publications/refresh", async () => orchestrator.refreshPublications());
  app.post("/v1/content/:id/generate", async (request) => orchestrator.generateContent(request.params.id));
  app.post("/v1/content/:id/refresh", async (request) => orchestrator.refreshContent(request.params.id));
  app.post("/v1/content/:id/qa", async (request) => orchestrator.reviewContent(request.params.id));
  app.post("/v1/content/:id/approve", async (request) => orchestrator.approveContent(request.params.id));
  app.post("/v1/content/:id/publish", async (request) => orchestrator.publishContent(request.params.id));

  app.setErrorHandler((error, request, reply) => {
    request.log.error(error);
    reply.code(error.statusCode && error.statusCode < 500 ? error.statusCode : 500).send({ error: error.message });
  });
  return app;
}
