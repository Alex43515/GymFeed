import Fastify from "fastify";

function tokenFrom(request, name) {
  const value = request.headers[name];
  return Array.isArray(value) ? value[0] : value;
}

export function buildApp({ config, orchestrator, cmo, logger = true }) {
  const app = Fastify({ logger });
  const legacyReview = (fn) => {
    if (cmo) throw new Error("Use the idea/asset decision actions in the main CMO; the old review path is disabled");
    return fn();
  };
  const guardedWork = async (id, operation, fn) => {
    if (!cmo) return fn();
    return cmo.campaigns.withWork(id, operation, fn);
  };

  app.addHook("onRequest", async (request, reply) => {
    if (!request.url.startsWith("/v1/")) return;
    const isApproval = /^\/v1\/content\/[^/]+\/approve(?:\?|$)/.test(request.url);
    const expected = isApproval ? config.MARKETING_APPROVAL_TOKEN : config.MARKETING_INTERNAL_TOKEN;
    const header = isApproval ? "x-marketing-approval-token" : "x-marketing-token";
    if (tokenFrom(request, header) !== expected) return reply.code(401).send({ error: "unauthorized" });
  });

  app.get("/health", async () => ({ ok: true, service: "gymfeed-marketing-worker" }));
  if (cmo) {
    app.post("/v1/cmo/execute", async (request) => cmo.execute(request.body ?? {}));
    app.post("/v1/cmo/decisions", async () => cmo.decisions());
    app.get("/v1/cmo/campaigns", async () => cmo.repository.campaignList());
    app.get("/v1/cmo/campaigns/:id", async (request) => cmo.campaigns.status(request.params.id));
  }
  app.post("/v1/runs/daily", async (request) => {
    const campaignDate = request.body?.campaign_date ? new Date(request.body.campaign_date) : new Date();
    if (Number.isNaN(campaignDate.getTime())) throw new Error("campaign_date must be an ISO date or date-time");
    const revision = request.body?.revision == null ? 1 : Number(request.body.revision);
    return orchestrator.runDaily(campaignDate, { revision });
  });
  app.post("/v1/runs/daily-batch", async (request) => {
    const startDate = request.body?.start_date ? new Date(request.body.start_date) : new Date();
    if (Number.isNaN(startDate.getTime())) throw new Error("start_date must be an ISO date or date-time");
    const days = request.body?.days == null ? 3 : Number(request.body.days);
    const revision = request.body?.revision == null ? 1 : Number(request.body.revision);
    return orchestrator.runDailyBatch(startDate, { days, revision });
  });
  app.post("/v1/runs/weekly", async () => orchestrator.runWeekly());
  app.post("/v1/runs/pipeline", async () => orchestrator.runPipeline());
  app.post("/v1/publications/refresh", async () => orchestrator.refreshPublications());
  app.post("/v1/reviews/sync", async () => legacyReview(() => orchestrator.syncApprovalSheet()));
  app.post("/v1/reviews/sync-content", async () => orchestrator.syncApprovalContent());
  app.post("/v1/reviews/claim", async () => legacyReview(() => orchestrator.claimApprovalSheetDecisions()));
  app.post("/v1/reviews/prepare", async (request) => {
    if (cmo) throw new Error("Use the main CMO decision dispatcher; legacy review preparation is disabled");
    return orchestrator.prepareClaimedReview(request.body ?? {});
  });
  app.post("/v1/reviews/complete", async (request) => orchestrator.completeClaimedReview(request.body ?? {}));
  app.post("/v1/content/:id/generate", async (request) => guardedWork(request.params.id, "generate", () => orchestrator.generateContent(request.params.id)));
  app.post("/v1/content/:id/refresh", async (request) => guardedWork(request.params.id, "refresh", () => orchestrator.refreshContent(request.params.id)));
  app.post("/v1/content/:id/qa", async (request) => guardedWork(request.params.id, "qa", () => orchestrator.reviewContent(request.params.id)));
  app.post("/v1/content/:id/process", async (request) => guardedWork(request.params.id, "produce", () => orchestrator.processContentToReview(request.params.id)));
  app.post("/v1/content/:id/approve", async (request) => legacyReview(() => orchestrator.approveContent(request.params.id)));
  app.post("/v1/content/:id/publish", async (request) => guardedWork(request.params.id, "publish", () => orchestrator.publishContent(request.params.id)));

  app.setErrorHandler((error, request, reply) => {
    request.log.error(error);
    reply.code(error.statusCode && error.statusCode < 500 ? error.statusCode : 500).send({ error: error.message });
  });
  return app;
}
