import { loadOutreachConfig } from "./config.mjs";
import { OutreachSheet } from "./sheet.mjs";
import { InstagramClient, verifyWebhookSignature } from "./instagram.mjs";
import { OutreachAI } from "./ai.mjs";
import { OutreachService } from "./service.mjs";

export function createOutreachService({ config, env = process.env, logger } = {}) {
  const outreachConfig = loadOutreachConfig(env);
  return new OutreachService({
    config: outreachConfig,
    logger,
    sheet: new OutreachSheet({
      spreadsheetId: outreachConfig.OUTREACH_SHEET_ID ?? config.GOOGLE_SHEETS_APPROVAL_ID,
      sheetName: outreachConfig.OUTREACH_SHEET_TAB,
      credentialsPath: config.GOOGLE_SHEETS_CREDENTIALS ?? env.GOOGLE_APPLICATION_CREDENTIALS,
    }),
    instagram: new InstagramClient({
      version: outreachConfig.INSTAGRAM_GRAPH_VERSION,
      businessAccountId: outreachConfig.INSTAGRAM_BUSINESS_ACCOUNT_ID,
      graphAccessToken: outreachConfig.INSTAGRAM_GRAPH_ACCESS_TOKEN,
      messagingAccessToken: outreachConfig.INSTAGRAM_MESSAGING_ACCESS_TOKEN,
    }),
    ai: new OutreachAI({
      apiKey: config.OPENAI_API_KEY,
      model: outreachConfig.OUTREACH_MODEL,
      discoveryModel: outreachConfig.OUTREACH_DISCOVERY_MODEL,
      reasoningEffort: outreachConfig.OUTREACH_REASONING_EFFORT,
      discoveryReasoningEffort: outreachConfig.OUTREACH_DISCOVERY_REASONING_EFFORT,
    }),
  });
}

// /v1/outreach/* sits behind the worker's x-marketing-token hook; /webhooks/instagram is public but signed by Meta.
export function registerOutreachRoutes(app, outreach) {
  app.post("/v1/outreach/weekly", async (request) => outreach.runWeekly({ target: request.body?.target }));

  app.register(async (scope) => {
    scope.addContentTypeParser("application/json", { parseAs: "buffer" }, (request, body, done) => {
      request.rawBody = body;
      try {
        done(null, body.length ? JSON.parse(body.toString("utf8")) : {});
      } catch (error) {
        error.statusCode = 400;
        done(error);
      }
    });

    scope.get("/webhooks/instagram", async (request, reply) => {
      const query = request.query ?? {};
      const token = outreach.config.INSTAGRAM_WEBHOOK_VERIFY_TOKEN;
      if (query["hub.mode"] === "subscribe" && token && query["hub.verify_token"] === token) {
        return reply.type("text/plain").send(String(query["hub.challenge"] ?? ""));
      }
      return reply.code(403).send({ error: "forbidden" });
    });

    scope.post("/webhooks/instagram", async (request, reply) => {
      if (!verifyWebhookSignature(request.rawBody, request.headers["x-hub-signature-256"], outreach.config.INSTAGRAM_APP_SECRET)) {
        return reply.code(401).send({ error: "invalid signature" });
      }
      if (outreach.config.OUTREACH_ENABLED) {
        outreach.handleInstagramWebhook(request.body).catch((error) => request.log.error(error, "Instagram webhook processing failed"));
      }
      return { received: true };
    });
  });
}
