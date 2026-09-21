# GymFeed AI marketing automation

## Verdict

The shared plan has the right overall shape: a reasoning model makes decisions, Supabase holds durable state and attribution, specialist media models generate assets, n8n schedules work, and a publisher distributes approved content. The implementation keeps that architecture but corrects four assumptions:

1. Use OpenAI Responses with `gpt-5.6-terra` for daily work and `gpt-5.6-sol` for weekly synthesis. Current official rates are configured separately for Terra ($2/$12 per million input/output tokens) and Sol ($4/$20), but remain environment variables so they can be updated without code changes.
2. fal.ai provides Nano Banana 2 start-frame/background imagery and queued Gemini Omni Flash 1.1 reference-to-video. A human-led or hybrid edit uses one ten-second continuous creator-style speaking clip anchored by a production start frame that locks the fictional adult, exact location, wardrobe, camera, and lighting. The actor performs only a simple direct-to-camera beat with empty or resting hands; no phone, food, weight, or equipment choreography is generated. Verified GymFeed screens provide the remaining product proof. The local compositor adds the exact GymFeed wordmark, Poppins captions, payoff, CTA, and gymfeed.io. Real-person face references are never uploaded.
3. Buffer is the publishing adapter, not the analytics source. Conversion truth comes from GymFeed product events and RevenueCat; Buffer delivery/metrics can supplement, but not replace, product conversion data.
4. Automatic publishing remains approval-gated and disabled by default. YouTube is private during the initial live test, and Instagram must be a Professional account for unattended publishing.

Verified references:

- [OpenAI GPT-5.6 Terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) and [API pricing](https://developers.openai.com/api/docs/pricing)
- [fal.ai Nano Banana 2 API](https://fal.ai/models/fal-ai/nano-banana-2/api) and [Gemini Omni Flash 1.1 reference-to-video API](https://fal.ai/models/google/gemini-omni-flash/v1.1/reference-to-video/api)
- [Buffer API quickstart](https://developers.buffer.com/guides/getting-started.html), [video posts](https://developers.buffer.com/examples/create-video-post.html), and [pricing](https://support.buffer.com/en-us/articles/buffer-pricing-and-features-6pJrOPuzIt)
- [TikTok Content Posting audit rules](https://developers.tiktok.com/doc/content-posting-api-get-started)
- [YouTube upload API](https://developers.google.com/youtube/v3/docs/videos/insert)
- [RevenueCat webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [GA4 Data API reporting](https://developers.google.com/analytics/devguides/reporting/data/v1/basics)

## Implemented architecture

```text
n8n schedules
    |
    v
marketing worker ----> OpenAI (quantified trend research, ranked creative decisions, QA, weekly learning)
    |  |-------------> fal.ai (Nano Banana 2 images + Gemini Omni Flash 1.1 video queue)
    |<---------------> Buffer (first-party post metrics + approved publishing)
    |<---------------- GA4 Data API (traffic, UTM acquisition, screens)
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
- `docs/marketing/screenshots/manifest.json` — semantic current-build screenshot catalog and public-use gate.
- `marketing/deploy/compose.yml` — pinned n8n, Postgres, worker, and Caddy.
- `marketing/deploy/workflows/00-main-cmo-orchestrator.json` — the main workflow that keeps one daily campaign or one rejected revision tied to its exact content IDs through generation, fal.ai polling, shot QA, final QA, and Google Sheet delivery.
- `marketing/deploy/workflows/` — supporting weekly learning, publication-status, and approval-watcher workflows.

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

Keep all provider secrets out of chat. The optional local import file accepts these labels:

```dotenv
OPENAI_API_KEY=your-new-key
SUPABASE_SERVICE_ROLE_KEY=your-new-sb_secret-key
FAL_KEY=your-fal-key
BUFFER_API_KEY=your-buffer-key
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

### 4. Connect GA4 reporting

The Flutter app contains Firebase Analytics for Android and web, and the web
Firebase configuration includes measurement ID `G-WSF2K1B6ZZ`. Deploy the web
build and enable Enhanced measurement in the GymFeed Web stream.

For the CMO's read-only report access:

1. Copy the numeric GA4 **Property ID** from Admin → Property details. Do not
   use the `G-` measurement ID or either stream ID.
2. Enable the Google Analytics Data API in a Google Cloud project.
3. Create a dedicated service account and grant its email **Viewer** access in
   GA4 Admin → Property access management.
4. Download its JSON key directly to
   `marketing/secrets/ga4-service-account.json`; the directory is Git-ignored.
5. Put the numeric property ID in `marketing/.env` as `GA4_PROPERTY_ID`.
6. Start or rebuild the worker with the credentials mounted read-only:

```powershell
docker compose -f marketing/deploy/compose.yml -f marketing/deploy/compose.ga4.yml --env-file marketing/.env up -d --build marketing-worker
```

The daily and weekly CMO calls then receive 7-day/30-day traffic totals, UTM
acquisition rows, and top app/web screens. If GA4 is unavailable, the worker
records that status in context and continues using Supabase conversion truth.

### 5. Main CMO workflow

`GymFeed 00 - Main CMO Orchestrator` is the normal campaign entry point. Its
manual trigger is configured as a one-day Gemini Omni Flash 1.1 test: it creates
one video and one carousel for the current campaign day. The 06:00 ET schedule
stays disabled during the test rollout to prevent unattended provider spend.
Enable it only after the one-day sample is approved. Both paths lock onto the
exact content IDs they create, generate the carousel and one continuous human
hero clip when selected, wait inside visible n8n Wait/poll loops, run
shot-level and final QA, and write the completed rows to the Google Sheet. The
execution cannot reach the Sheet node unless every asset in that execution has
status `awaiting_approval`.

Keep `GymFeed 05 - Google Sheet Decision Dispatcher` as the separate one-minute
watcher. It claims each new decision exactly once and invokes the main workflow
with `contentId`, revision, decision, and reviewer instructions. Reject revises
and regenerates only that content; it does not rerun daily research. The legacy
`GymFeed 01 - Daily CMO` and `GymFeed 02 - Content Pipeline` workflows are useful
for diagnostics but must remain inactive when the main workflow is scheduled,
otherwise they can create or advance work independently.

### 6. Brain-only shadow mode

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

### 7. Private asset generation

Change `GENERATE_ASSETS=true`, redeploy the worker, and run “GymFeed 00 - Main CMO Orchestrator” manually. Keep `AUTO_PUBLISH=false`. The manual test generates one Gemini Omni Flash 1.1 video and one carousel for the current campaign day, polls, uploads, runs QA, and syncs both assets to the approval sheet. It stops at `awaiting_approval`; nothing is sent to Buffer until approved.

For the first 10–20 assets, still perform a human review. Automated QA checks a nine-frame chronological contact sheet for the raw hero clip and a 16-frame contact sheet for the final edit. The one-day test allows at most two provider attempts. A failed first clip is retried only with the same locked reference and the QA-generated corrective prompt; no new strategy, carousel, or CMO plan is created.

```powershell
Invoke-RestMethod -Method Post `
  -Uri "http://127.0.0.1:3000/v1/content/CONTENT_UUID/approve" `
  -Headers @{ "x-marketing-approval-token" = "YOUR_APPROVAL_TOKEN" }
```

The reference deployment binds the worker only to the server's loopback address. Run this on the server or through an SSH tunnel; it is not published through Caddy.

### 7a. Google Sheet approval queue

The approval queue uses a native Google Sheet as a human control surface while
Supabase remains the source of truth. Each row contains preview and asset URLs,
the content plan, QA result, separate `Video decision` / `Video instructions`
and `Carousel decision` / `Carousel instructions` controls, and the processing
result. Only the control pair matching the row's content type is populated and
read by the dispatcher.

1. Enable the Google Sheets API in the same Google Cloud project used by the
   GA4 service account.
2. Import `outputs/gymfeed-approval-sheet/GymFeed-Marketing-Approval.xlsx` as a
   native Google Sheet.
3. Share the sheet with the service-account email as Editor.
4. Copy the spreadsheet ID from the URL between `/d/` and `/edit` into
   `GOOGLE_SHEETS_APPROVAL_ID` in `marketing/.env`.
5. Keep `GOOGLE_SHEETS_APPROVAL_TAB=Content Review` and point
   `GOOGLE_SHEETS_CREDENTIALS` at the mounted service-account JSON.
6. Apply `0031_marketing_content_reviews.sql`, rebuild the worker, import
   `GymFeed 05 - Google Sheet Decision Dispatcher`, and activate it after a manual test.

`Approve` records an auditable decision and sends eligible content to Buffer
when `AUTO_PUBLISH=true`. `Reject` requires revision instructions; the dispatcher
claims the row and calls the revision trigger on the main orchestrator. The CMO
creates a corrected plan, increments the revision, regenerates only that content,
repeats all QA gates, and returns the new revision to the same Sheet row. The
review table is the idempotency boundary, so the one-minute checker cannot
publish or regenerate the same content revision twice.

### 8. Publishing rollout

Connect Instagram Professional, TikTok, and YouTube accounts in Buffer. Use `BufferPublisher.listChannels()` or Buffer's API Explorer to obtain each channel ID, then store the IDs in the local environment file. Instagram Personal accounts cannot publish automatically.

Set Buffer channel IDs and `AUTO_PUBLISH=true`, redeploy, then activate “GymFeed 04 - Publication Status.” Keep `BUFFER_YOUTUBE_PRIVACY=private` for the first test. Start with one approved test post per platform and confirm the actual post, caption, AI disclosure, tracking URL, and publication status before allowing scheduled publishing to continue.

## Operating rules

- Monthly defaults: OpenAI $25, fal.ai $25 prepaid, Buffer $18 for three Essentials channels, infrastructure $10, total ceiling $180. Every metered provider operation reserves budget atomically before it runs.
- A failed or duplicated n8n execution cannot create a second daily/weekly decision because runs use date/week idempotency keys.
- Exact carousel text is rendered locally with GymFeed's Poppins assets; fal.ai only generates background imagery.
- Only screenshots marked `marketing_safe` in the current-build manifest can be selected or rendered by the CMO. Raw captures remain an archive and are not automatically marketing-approved.
- Content is never public unless it passes structured QA, receives approval, and `AUTO_PUBLISH=true`.
- Keep a human approval gate until at least two weeks of clean operation and until platform account audits are complete. Video review should remain human-assisted even later unless full-video QA is added.
- Buffer status is operational delivery data. GA4 supplies traffic and screen engagement; Supabase product events and RevenueCat remain conversion truth.

## How the CMO now chooses creative

The daily run is deliberately split into two model calls:

1. A quantitative researcher searches current platform/trend evidence and combines it with historical GymFeed post metrics read from Buffer. Every usable evidence item must include a sourced number such as views, shares, saves, watch time, retention, reach, or search interest.
2. The CMO creates exactly three different concepts, cites the evidence IDs behind each one, scores them with a fixed weighted rubric, and chooses the highest-value treatment. The treatment explicitly controls whether production is human-led, hybrid, or product-led.

Availability of screenshots never overrides that choice. Human-led and hybrid decisions send a narrative human-action brief to fal.ai, then add only the verified GymFeed screens needed for product proof. Product-led decisions remain available when quantified evidence supports a direct UI demonstration. Buffer metrics are refreshed after publication and feed the next daily and weekly decisions; GA4 and Supabase remain responsible for traffic, registration, activation, and subscription outcomes.

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
