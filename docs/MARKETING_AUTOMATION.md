# GymFeed AI marketing automation

## Verdict

The shared plan has the right overall shape: a reasoning model makes decisions, Supabase holds durable state and attribution, specialist media models generate assets, n8n schedules work, and a publisher distributes approved content. The implementation keeps that architecture but corrects four assumptions:

1. Use OpenAI Responses with `gpt-5.6-terra` for daily work and `gpt-5.6-sol` for weekly synthesis. Current official rates are configured separately for Terra ($2.50/$15 per million input/output tokens) and Sol ($5/$30), but remain environment variables so they can be updated without code changes.
2. The current documented BytePlus model is Dreamina Seedance 2.0 (`dreamina-seedance-2-0-260128`), not an unverified “Seedance 2.5.” The first version generates one 4–15 second scene and never uploads real-person face references.
3. Blotato is the publishing adapter, not the analytics source. Conversion truth comes from GymFeed product events and RevenueCat; platform metrics need direct platform/GA4 connectors when credentials and review access are available.
4. TikTok and YouTube can restrict unaudited API publishing. Public automation is therefore approval-gated and starts disabled.

Verified references:

- [OpenAI GPT-5.6 Terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) and [API pricing](https://developers.openai.com/api/docs/pricing)
- [Gemini image generation](https://ai.google.dev/gemini-api/docs/image-generation) and [pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [BytePlus Seedance 2.0 task API](https://docs.byteplus.com/en/docs/ModelArk/2298881)
- [Blotato API quickstart](https://help.blotato.com/api/start) and [publish endpoint](https://help.blotato.com/api-reference/publish-post)
- [TikTok Content Posting audit rules](https://developers.tiktok.com/doc/content-posting-api-get-started)
- [YouTube upload API](https://developers.google.com/youtube/v3/docs/videos/insert)
- [RevenueCat webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [GA4 Data API reporting](https://developers.google.com/analytics/devguides/reporting/data/v1/basics)

## Implemented architecture

```text
n8n schedules
    |
    v
marketing worker ----> OpenAI (research, decisions, QA, weekly learning)
    |  |  |----------> Gemini (image backgrounds)
    |  |-------------> BytePlus (short video task + polling)
    |----------------> Blotato (approved social publishing)
    |
    v
Supabase
  - plans, assets, QA, approvals, publications
  - atomic monthly/provider budgets
  - signup, onboarding, first-workout and RevenueCat outcomes
  - durable learnings and idempotent workflow runs
```

The important files are:

- `supabase/migrations/0017_marketing_automation.sql` — state, RLS, attribution, events, budget ledger, and storage bucket.
- `supabase/functions/revenuecat-webhook/index.ts` — authenticated and deduplicated subscription events.
- `marketing/src/orchestrator.mjs` — the state machine and safety gates.
- `marketing/src/brain.mjs` — structured OpenAI Responses calls.
- `marketing/deploy/compose.yml` — pinned n8n, Postgres, worker, and Caddy.
- `marketing/deploy/workflows/` — four inactive importable n8n workflows.

## Activation sequence

Do not skip directly to public autopublishing. Each phase has a separate switch.

### 1. Apply the Supabase backend

From the repository root, with the Supabase CLI linked to the intended project:

```powershell
supabase db push
& marketing/scripts/configure-revenuecat-webhook.ps1
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

In RevenueCat, add this webhook URL and use the same authorization value as a Bearer token:

```text
https://YOUR_PROJECT.supabase.co/functions/v1/revenuecat-webhook
Authorization: Bearer <the REVENUECAT_WEBHOOK_AUTH value from marketing/.env>
```

Send RevenueCat's test event and confirm a `subscription_webhook_test` row appears in `marketing_events`.

### 2. Prepare the worker without spending or publishing

```powershell
& marketing/scripts/bootstrap-env.ps1
```

The bootstrap script creates the Git-ignored `marketing/.env` and generates separate random values for the internal token, approval token, Postgres password, and n8n encryption key. Provider credentials remain blank.

After rotating the OpenAI key and creating a new Supabase `sb_secret_` key, keep the new values out of chat and put only these two entries in `Desktop\keys.txt`:

```dotenv
OPENAI_API_KEY=your-new-key
SUPABASE_SERVICE_ROLE_KEY=your-new-sb_secret-key
```

Import them without displaying their values:

```powershell
& marketing/scripts/import-provider-keys.ps1
```

The environment variable retains its historical name, but it should contain the new Supabase `sb_secret_` key rather than a legacy service-role JWT. Never expose this key in Flutter or n8n workflow JSON.

Keep these settings initially:

```dotenv
GENERATE_ASSETS=false
AUTO_PUBLISH=false
```

Set the landing URL to a real GymFeed page that preserves `utm_source`, `utm_campaign`, and `utm_content`. The included Flutter handler stores the first UTM touch from web or `app_links` and calls `claim_marketing_attribution` after authentication. The database only accepts a valid GymFeed content/publication key, attributes the signed-in user, and preserves first touch.

Firebase Dynamic Links shut down in 2025. A custom `com.flutterflow.gymfeedofficial://` scheme is included as an interim app-opening fallback, but the production landing domain must be configured for Android App Links and iOS Universal Links (including `assetlinks.json` and `apple-app-site-association`) before mobile install/open attribution is considered complete.

### 3. Deploy n8n and the worker

For local setup, the bootstrap script configures n8n at `http://localhost:5678`. Start the credential-independent services first:

```powershell
cd marketing/deploy
docker compose --env-file ../.env up -d postgres n8n
docker compose --env-file ../.env exec -T n8n n8n import:workflow --separate --input=/imports
```

Create the local owner account and review the imported inactive workflows. Do not activate them until the provider credentials, Supabase migration, and worker are ready.

For a public server deployment, set `N8N_PROTOCOL=https`, `N8N_PUBLIC_URL=https://N8N_DOMAIN`, and `N8N_SECURE_COOKIE=true`. Point the `N8N_DOMAIN` DNS A/AAAA record at the server first, then run:

```powershell
cd marketing/deploy
docker compose --env-file ../.env config
docker compose --env-file ../.env up -d --build
docker compose --env-file ../.env exec n8n n8n import:workflow --separate --input=/imports
```

Open `https://N8N_DOMAIN`, create the n8n owner account, enable MFA, and review each workflow. They import inactive. Do not expose the worker port publicly; only n8n reaches it on the Docker network.

### 4. Brain-only shadow mode

Enable the database control, leaving asset generation and publishing off:

```sql
update public.marketing_brand_config
set enabled = true, manual_approval_required = true
where id = 'gymfeed';
```

Activate only “GymFeed 01 - Daily CMO” and “GymFeed 03 - Weekly CMO.” Run the daily workflow manually once. Inspect:

- source URLs and factual claims;
- content decisions and risk flags;
- expected product features and calls to action;
- the OpenAI cost reservation/settlement.

### 5. Private asset generation

Change `GENERATE_ASSETS=true`, redeploy the worker, and activate “GymFeed 02 - Content Pipeline.” Keep `AUTO_PUBLISH=false`. The pipeline will generate, poll, upload, and QA assets. It will stop at `awaiting_approval`.

For the first 10–20 assets, check every frame of video manually; automated QA sees generated images and the video's last frame, not the entire video. Only approve content using the separate header:

```powershell
Invoke-RestMethod -Method Post `
  -Uri "http://127.0.0.1:3000/v1/content/CONTENT_UUID/approve" `
  -Headers @{ "x-marketing-approval-token" = "YOUR_APPROVAL_TOKEN" }
```

The reference deployment binds the worker only to the server's loopback address. Run this on the server or through an SSH tunnel; it is not published through Caddy.

### 6. Publishing rollout

Connect Instagram Professional, TikTok, and YouTube accounts in Blotato. Complete any required TikTok/YouTube audits before assuming public delivery works. Blotato starts a paid plan when its API key is generated, so create that key only when ready.

Set Blotato account IDs and `AUTO_PUBLISH=true`, redeploy, then activate “GymFeed 04 - Publication Status.” Start with one approved test post per platform. Confirm the actual platform post, caption, AI disclosure, tracking URL, and publication status before allowing the scheduled pipeline to continue.

## Operating rules

- Monthly defaults: OpenAI $25, Gemini $15, BytePlus $100, Blotato $29, infrastructure $10, total $180. Every provider operation reserves budget atomically before it runs.
- A failed or duplicated n8n execution cannot create a second daily/weekly decision because runs use date/week idempotency keys.
- Exact carousel text is rendered locally with GymFeed's Poppins assets; Gemini only generates imagery.
- Content is never public unless it passes structured QA, receives approval, and `AUTO_PUBLISH=true`.
- Keep a human approval gate until at least two weeks of clean operation and until platform account audits are complete. Video review should remain human-assisted even later unless full-video QA is added.
- Blotato status is operational delivery data. Use first-party product/RevenueCat outcomes for optimization; add direct platform and GA4 reporting later rather than inventing metrics.

## Validation commands

```powershell
cd marketing
npm ci
npm test
npm run check

cd deploy
docker compose --env-file ../.env config
docker compose --env-file ../.env build marketing-worker
```

No provider calls are made by the test suite. Live smoke tests require real credentials and can incur charges.
