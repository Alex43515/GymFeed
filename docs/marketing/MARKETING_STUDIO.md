# GymFeed Marketing Studio

Local dashboard: http://127.0.0.1:3100

## Start locally

1. Start Docker Desktop.
2. In `marketing/deploy`, run `docker compose --env-file ../.env up -d postgres n8n marketing-worker`.
3. In `marketing/dashboard`, run `npm ci`, then `npm run dev`.
4. Open http://127.0.0.1:3100. The worker is on loopback port 3000 and n8n on 5678.

After the first dependency install, `npm run studio` in `marketing` starts the
Docker services and the dashboard together. Keep the dashboard terminal open.

The dashboard is a separate Next.js application. It does not modify the public
GymFeed website. Its server proxy holds the internal token; browser code never
receives provider keys, the Supabase service-role key or the worker token.
The current preview accepts loopback hosts and same-origin writes only. Add
owner authentication and authorization before hosting it publicly. Publishing
the static GymFeed website does not deploy this server application.

## Connected process

- Research → evidence-backed campaign ideas → individual owner approval.
- Verified source recordings → generation/assembly → owner review → Buffer.
- First-party events, publication data, costs and creative archive → weekly CMO.
- Research, creative, community, analytics, email, partnerships and SEO briefs
  are persisted as job results. Email/CRM delivery is visibly unconnected;
  those outputs are drafts, not sent messages or published website changes.
- Sheets remain synchronized for compatibility; the dashboard can approve or
  reject a current revision without requiring the owner to edit a Sheet row.

## Analytics

Open `http://127.0.0.1:3100/#analytics`. Registrations are counted from
recorded profile signup events. Existing profiles and historical signups have
separate totals. Daily grouping and timestamps use Europe/Belgrade. Only a
recorded publication ID counts as an attributed signup for that post.

Post metrics come from all paginated Buffer results on the configured GymFeed
channels. Published records already saved in Supabase remain available if Buffer
fails. Counts reflect each post's latest reported metrics. The registration
date filter applies to registrations, and audience reports show their own period.

Set the optional audience credentials on the worker in `marketing/.env`.

- Instagram account audience uses `INSTAGRAM_BUSINESS_ACCOUNT_ID` and
  `INSTAGRAM_INSIGHTS_TOKEN` for the GymFeed professional account with
  `instagram_manage_insights` access via Facebook Login.
- YouTube channel and per-video audience reports use
  `YOUTUBE_ANALYTICS_CLIENT_ID`, `YOUTUBE_ANALYTICS_CLIENT_SECRET` and
  `YOUTUBE_ANALYTICS_REFRESH_TOKEN`. Authorize the channel owner's OAuth
  account with `https://www.googleapis.com/auth/yt-analytics.readonly`.
- TikTok audience details and Instagram per-post demographics can be opened
  in the native analytics tools from Studio when available on the account.

Recreate the worker after changing its environment. Missing metrics, absent
permissions and withheld audience breakdowns have explicit states in the UI.

## Durable jobs and recovery

`marketing_studio_jobs` stores explicit operations, stable request keys,
attempt counts, results, next retry time, heartbeat and error classification.
`marketing_studio_events` preserves each attempt, API failure and n8n incident.
Both tables have RLS and service-role-only access.

The worker claims jobs using a database function with `FOR UPDATE SKIP LOCKED`.
The normal queue processor and n8n dispatcher cannot claim the same row twice.
Job heartbeats run every 20 seconds. Expired leases require attention rather
than replaying a potentially paid provider request. Successful records remain
in the history. Queued work can be cancelled; accepted provider work cannot.

Temporary, replay-safe failures retry with exponential backoff and jitter,
up to three attempts. Missing assets, credentials, budget and moderation
failures display their actual reason and the required next action. Ambiguous
provider timeouts require inspection of saved tasks; they are not silently
charged again. Moderation and stale approvals require review or revision.
The content-level Resume action follows the existing approved-revision gates
and reuses stored tasks/footage. It does not grant a fresh paid remake.

n8n **08 — Studio Job Dispatcher** wakes the queue every minute.
n8n **09 — Shared Error Handler** records workflow, failing node and execution
identifier in Studio. Existing GymFeed workflows reference this error handler.
The worker also drains the durable queue independently, so a slow n8n editor
does not lose an accepted action.

`node marketing/scripts/install-studio-workflows.mjs` backs up live n8n exports,
preserves their nodes and activation states, installs the two workflows and
attaches the handler. Restart n8n afterward so its running scheduler loads the
published definitions. Backups stay in ignored `.dashboard-runtime/`.

## Source recordings

The item drawer shows required filenames and the linked Drive folder. The
owner can also upload an MP4 directly, describing the actions actually visible
and confirming that privacy/branding were checked. The existing intake checks
the filename, computes its hash and probes duration before registering it.
It is not an AI certification that the declared actions occurred. Production
uses the normal source-window checks and preserves sanitized recordings.

## CMO v4: reducing repeated ideas

The repository loads up to 400 records from 90 days. Derived platform variants
are excluded from creative comparisons. Detailed recent context remains
bounded, while creative memory includes up to 60 daily / 90 weekly master
assets and a separate saturation summary covers up to 240.

The intelligence summary is sent explicitly before the long decision context
so it cannot disappear behind a truncation boundary. It tracks formats,
settings, features, repeated hooks and the last twelve video premises.
Autonomous plans are rejected when their hook substantially repeats one of
the previous thirty assets of that type. This lexical guard does not claim
to detect every semantic duplicate. Owner-directed revisions retain priority.

The CMO now starts with audience tension and a measurable hypothesis, compares
different premises/structures/payoffs, and states why a concept wins and how it
could fail. A new actress, location or feature alone is not a fresh concept.
Views, scheduled status and QA scores cannot establish a conversion winner.
Missing attribution stays explicitly unavailable rather than becoming zero ROI.

## Research and prompt sources

Reviewed 2026-11-04. Prompts are tailored to GymFeed, not copied as a purported
universally best CMO prompt.

- [ReStructure blueprint](https://restructure-europe.vercel.app/en/newsletter/marketing-team/):
  department coverage, knowledge layer, owner handoff and feedback loops.
  Its public diagram is an architectural reference, not measured proof.
- [TikTok creative guide](https://ads.tiktok.com/business/en/guides/what-is-ad-creative-guide):
  platform-native opening, understandable story, captions and creative testing.
- [Anthropic workflow patterns](https://www.anthropic.com/research/building-effective-agents):
  bounded research/creation/evaluation stages with explicit checks.
- [n8n error handling](https://docs.n8n.io/flow-logic/error-handling/):
  a shared Error Trigger workflow and execution context for recovery.

Versioned instructions live in `marketing/src/studio-strategy.mjs`; they feed
the daily planner, weekly review and department briefs. Existing casting,
authentic product footage, voice/continuity and human-review policies remain
part of the production contracts. Better model scores alone do not guarantee
a better GymFeed video; final acceptance still belongs to the owner.

## Verification

- `npm test` in `marketing`: queue duplication/concurrency, backoff, redaction,
  approval boundaries, missing assets, video adapters and existing pipeline.
- `npm run check` and `npm run build` in `marketing/dashboard`.
- Live checks: real campaign snapshot, stable job idempotency, a persisted
  analytical brief, n8n dispatch execution, and protected server-only secrets.

Public hosting, multiple-client tenancy and external email/CRM credentials are
not implied by the local preview. Use a separate server-capable deployment for
`marketing.gymfeed.io`; retain private access and existing owner approval gates.
