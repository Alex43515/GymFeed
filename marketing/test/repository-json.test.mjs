import test from "node:test";
import assert from "node:assert/strict";
import { jsonSafe, MarketingRepository } from "../src/repository.mjs";

test("jsonSafe strips characters Postgres jsonb rejects", () => {
  const cleaned = jsonSafe({ hook: "Plan\u0000 it", slides: [{ body: "a\uD800b" }], emoji: "ok \u{1F4AA}", count: 3 });
  assert.deepEqual(cleaned, { hook: "Plan it", slides: [{ body: "ab" }], emoji: "ok \u{1F4AA}", count: 3 });
});

test("marketing asset upload retries empty transient errors and returns the public URL", async () => {
  let attempts = 0;
  const bucket = {
    upload: async () => {
      attempts += 1;
      return attempts < 3 ? { data: null, error: { message: "<none>", statusCode: 503 } } : { data: { path: "asset.png" }, error: null };
    },
    getPublicUrl: (path) => ({ data: { publicUrl: `https://assets.example/${path}` } }),
  };
  const repository = new MarketingRepository({ SUPABASE_URL: "https://example.supabase.co", SUPABASE_SERVICE_ROLE_KEY: "service", SUPABASE_MARKETING_BUCKET: "assets", STORAGE_RETRY_DELAY_MS: 0 }, { storage: { from: () => bucket } });
  assert.equal(await repository.uploadAsset("asset.png", Buffer.from("image"), "image/png"), "https://assets.example/asset.png");
  assert.equal(attempts, 3);
});

test("marketing asset upload preserves useful provider details after bounded retries", async () => {
  const bucket = {
    upload: async () => ({ data: null, error: { message: "<none>", statusCode: 503, code: "storage_unavailable" } }),
    getPublicUrl: () => ({ data: { publicUrl: "" } }),
  };
  const repository = new MarketingRepository({ SUPABASE_URL: "https://example.supabase.co", SUPABASE_SERVICE_ROLE_KEY: "service", SUPABASE_MARKETING_BUCKET: "assets", STORAGE_RETRY_DELAY_MS: 0 }, { storage: { from: () => bucket } });
  await assert.rejects(repository.uploadAsset("asset.png", Buffer.from("image"), "image/png"), /503.*storage_unavailable/);
});

test("unsupported audio MIME is a configuration error, not three retries of the same upload", async () => {
  let attempts=0;
  const repository=new MarketingRepository({SUPABASE_MARKETING_BUCKET:"assets"},{storage:{from:()=>({upload:async()=>{attempts++;return{error:{message:"mime type audio/mpeg is not supported",statusCode:415,code:"InvalidMimeType"}};}})}});
  await assert.rejects(repository.uploadAsset("voice.mp3",Buffer.from("audio"),"audio/mpeg"),error=>error.safeToRetry===true&&/InvalidMimeType/.test(error.message));
  assert.equal(attempts,1);
});

test("marketing cost settlement resumes safely when the reservation was already settled", async () => {
  let ledgerReads = 0;
  const repository = new MarketingRepository({ SUPABASE_URL: "https://example.supabase.co", SUPABASE_SERVICE_ROLE_KEY: "service" }, {
    rpc: async () => ({ data: null, error: { message: "active reservation not found" } }),
    from: () => ({
      select: () => ({
        eq: () => ({
          maybeSingle: async () => {
            ledgerReads += 1;
            return { data: { status: "settled", actual_cost_usd: 0.5, external_ref: "task-1" }, error: null };
          },
        }),
      }),
    }),
  });

  const result = await repository.settleCost("reservation-1", 0.5, "task-1");
  assert.equal(result.status, "settled");
  assert.equal(ledgerReads, 1);
});
