# GymFeed — Firebase → Supabase Migration Plan

Status: **planning approved, awaiting access** (see §2).
Repo: `https://github.com/Alex43515/GymFeed.git` (local repo initialized, push pending access).
Schema: [`supabase/migrations/0001_initial_schema.sql`](../supabase/migrations/0001_initial_schema.sql) — complete Postgres schema + RLS mirroring the Firestore model.

---

## 1. Scope

Migrate GymFeed (Flutter/FlutterFlow, ~412 Dart files) off Firebase entirely:

| Firebase service | Replacement |
|---|---|
| Firebase Auth (email, Google, Apple) | Supabase Auth (users imported with password hashes — no password resets) |
| Firestore (~20 collections) | Postgres with RLS (schema in `supabase/migrations/`) |
| Firebase Storage | Supabase Storage (images) + **Bunny Stream** (video) |
| Cloud Functions (push fan-out, user-delete cleanup) | Supabase Edge Functions + `ON DELETE CASCADE` |
| FCM | **Kept** — FCM works standalone; Edge Function calls FCM HTTP v1 API |
| Dynamic Links | Already dead (Google sunset Aug 2025) → App Links / Universal Links |
| Firebase Performance | Sentry (also adds crash reporting, which is currently missing) |
| RevenueCat, Google Maps/Places | Unaffected |

---

## 2. Access needed and how to grant it

Secrets go into a local **`.env.migration`** file in the repo root (gitignored — never committed, never pasted into chat).

| # | What | Why | How to grant |
|---|---|---|---|
| 1 | **GitHub repo** `Alex43515/GymFeed` | Push code, PRs, CI | Repo doesn't exist yet or is private. Either (a) create it **private** and add `aleksandarzivkovic-DRT` (already authenticated on this machine) as collaborator: *Settings → Collaborators → Add people*, or (b) run `gh auth login` here as `Alex43515`. |
| 2 | **Supabase project** | Target backend | Create org + project at supabase.com (pick region near your users; EU Frankfurt if Balkans-centric). Save the **database password**. |
| 3 | **Supabase access token** | Lets the CLI link the project, push migrations, deploy Edge Functions, set secrets | Dashboard → *Account → Access Tokens → Generate new token* → `SUPABASE_ACCESS_TOKEN` in `.env.migration`. Also add `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD`, `SUPABASE_SERVICE_ROLE_KEY` (Project → Settings → API). |
| 4 | **Firebase service account** | Export Firestore + Storage via Admin SDK (ETL) | Firebase console → *Project settings → Service accounts → Generate new private key* → save as `serviceAccountKey.json` in repo root (gitignored). |
| 5 | **Firebase Auth export + hash params** | Import users into Supabase keeping passwords | Run `firebase login` once on this machine (needs Owner/Editor on the project). Then: Console → *Authentication → Users → ⋮ → Password hash parameters* — copy `signer_key`, `salt_separator`, `rounds`, `mem_cost` into `.env.migration`. |
| 6 | **Bunny.net** | Video pipeline (Stream) + image CDN | Dashboard → create a **Stream Video Library** → copy `BUNNY_STREAM_LIBRARY_ID` + the library-scoped API key `BUNNY_STREAM_API_KEY`. Also the account API key if I should script the pull-zone setup. These become Edge Function secrets, never shipped in the app. |
| 7 | **Google OAuth client** | Google sign-in via Supabase | Google Cloud Console → *APIs & Credentials → OAuth 2.0 Client IDs* → add `https://<project-ref>.supabase.co/auth/v1/callback` as authorized redirect URI → provide client ID + secret (configured in Supabase Auth dashboard). |
| 8 | **Apple Sign In** | Apple sign-in via Supabase | Apple Developer → Services ID + Sign in with Apple key (.p8). Provide Services ID, Team ID, Key ID, key file. Add the same Supabase callback URL. |
| 9 | **Gemini API key (new)** | AI features server-side | The old key is hardcoded in the app (`lib/backend/gemini/gemini.dart`) and must be **revoked**. Create a new key at aistudio.google.com → `GEMINI_API_KEY` → stored only as an Edge Function secret. |
| 10 | **FCM v1 credentials** | Push notifications post-migration | Covered by the same service account JSON from #4 (needs `cloudmessaging.messages.create`). Stored as Edge Function secret. |

Nothing else is needed: RevenueCat public SDK keys stay in the client (by design), Maps keys stay client-side but must be app-restricted in Google Cloud Console.

---

## 3. Execution phases

### Phase 0 — Repo + safety net (done / in progress)
- [x] `git init`, `.gitignore`, initial commit, remote configured
- [ ] Push to GitHub (**blocked on access #1**)
- [ ] Deploy fixed Firestore rules (the current ones leak DMs and PII — we run on Firebase for weeks during this migration, the holes can't stay open)
- [ ] Revoke leaked Gemini key; restrict Maps keys
- [ ] Add Sentry for crash visibility during the migration

### Phase 1 — Supabase foundation (week 1)
- Create project, `supabase link`, apply `0001_initial_schema.sql`
- Create Storage buckets: `avatars`, `images` (public-read, owner-write via storage policies scoped to `auth.uid()` path prefix)
- Configure Auth providers (email, Google, Apple), SMTP for verification emails
- Set up Bunny Stream library; connect webhook → Edge Function

### Phase 2 — Auth migration (week 2)
- `firebase auth:export users.json --format=json`
- Import via Supabase's Firebase-scrypt support (admin API / `supabase-firebase-auth-migrator`), preserving Firebase UIDs as Supabase user IDs → all FKs map 1:1, **users keep their passwords**
- Verify: email+password login, Google, Apple against a staging build

### Phase 3 — Data layer rewrite (weeks 3–6, the bulk)
Replace the generated Firestore layer behind a repository API so the 300+ widget files change minimally:

- `lib/backend/supabase/` — `supabase_flutter` client, typed row classes matching the `*Record` shapes
- One repository per domain: posts, comments, stories, chats, follows, notifications, trainings, workouts, meals, profile
- Firestore streams → Supabase **Realtime** only where liveness matters (chat, notifications); everything else becomes paginated `select()` (the reels page currently streams the *entire* `userTrainings` collection — this is where that gets fixed)
- Feed → `feed_page()` RPC (already in the schema): one round-trip, keyset pagination, no N+1
- Edge Functions:
  - `create-upload` — media upload tickets (see §4)
  - `media-webhook` — Bunny encode callbacks
  - `push-worker` — drains `push_queue` via FCM HTTP v1
  - `gemini-proxy` — all AI calls server-side (auth-gated, rate-limited; key never in app)
  - `delete-account` — auth user delete → cascades handle DB; function purges Storage + Bunny Stream objects (closes the current GDPR gap)
- Replace Dynamic Links with App Links/Universal Links (plain https deep links, `applinks:` + `assetlinks.json`)

### Phase 4 — ETL + cutover (weeks 7–8)
1. Node ETL script (`tools/etl/`): Admin SDK export → transform (refs→FKs, arrays→join rows, string dates→timestamptz) → `COPY` into Postgres. Idempotent, re-runnable, row-count + spot-check validation.
2. Media backfill: copy Storage objects → Supabase Storage; re-ingest videos into Bunny Stream (keeps old `legacy_*_url` columns working during transition).
3. Rehearse full ETL against staging twice.
4. Cutover: content freeze (a few hours), final delta run, release app v3.0, keep Firebase read-only for 30–60 days as rollback, then decommission.

**Estimate: 7–9 weeks** single developer, compressible if user count is still small.

---

## 4. Media architecture at 100k+ users

### Load model
100k registered ≈ ~30k DAU. Uploads: ~5% post daily → **3–5k media uploads/day**, evening peaks maybe 10–20/min. Delivery: 30k DAU × ~50 video views/day ≈ **1.5M plays/day ≈ 4–5 TB/day**. Conclusion: *upload control-plane load is trivial; delivery bandwidth is the real cost/scale problem; the origin must never serve bytes at scale.*

### Core principle: bytes never touch our middleware
The current app uploads through the Firebase SDK and plays full progressive MP4s. Any middleware that proxies file bytes (an API server receiving 100 MB uploads) becomes the bottleneck and a cost sink. Instead the middleware is **control-plane only** — it issues permissions and reacts to events; the data plane goes client ↔ CDN/storage directly:

```
VIDEO UPLOAD
 Flutter app ──1. POST /create-upload (JWT)──▶ Edge Function
                                               │ auth ✓  rate-limit ✓  quota ✓
                                               │ INSERT media_assets(status=pending)
                                               │ Bunny API: create video object
             ◀─2. TUS upload URL + signature───┘
 Flutter app ──3. TUS resumable upload (direct)──▶ Bunny Stream
                                                    │ transcode → HLS ladder
                                                    │ (240p…1080p) + poster
                                                    │ + animated preview
 Edge Fn  ◀───4. webhook: VideoEncoded──────────────┘
   │ verify signature → media_assets.status='ready'
   │ → post visible; Realtime notifies author
   └─▶ 5. async moderation: thumbnail → Gemini vision → flag/quarantine

PLAYBACK
 Flutter app ──HLS (video_player, native support)──▶ Bunny CDN edge (~119 PoPs)
             cache hit ≈ 99% — origin sees almost nothing
```

### Component decisions

**Compressor — server-side, not on-device.** The current `video_compress` flow (4 duplicate implementations) burns minutes of battery per upload with device-dependent quality — and at 100k users you still can't trust client output. Bunny Stream transcodes server-side into a proper ABR ladder for every video. Optionally keep a *light* client step (trim to max length, cap at 1080p via the hardware encoder) purely to shrink mobile upload bytes ~2–4×; the pipeline is correct without it.

**Uploads — resumable TUS, direct-to-provider.** Gym uploads happen on flaky mobile networks; TUS survives network switches and app backgrounding. Images: client-side resize (`flutter_image_compress`, ≤2048 px, ~85 quality) + blurhash computed locally → signed upload URL into Supabase Storage (path `user_id/…` enforced by storage RLS).

**Storage — split by type.** Videos in Bunny Stream (transcoding + delivery in one, ~$0.005/GB egress vs Firebase's $0.12 — at 150 TB/mo that's roughly $750 vs ~$18k). Images in Supabase Storage fronted by the existing Bunny pull zone with long-TTL immutable cache headers (content-addressed paths).

**Middleware — yes, but thin and serverless.** Four Edge Functions (upload tickets, webhooks, push worker, Gemini proxy). All stateless Deno isolates → horizontal autoscale, nothing to operate. Rate limits and quotas live in Postgres (`media_assets` counters per user/day).

**Display at scale.**
- `media_assets` carries blurhash + thumbnail + status → feed renders instantly with placeholders, players attach lazily
- Reels: paginated query (10/page) + 3-controller window (current playing, next pre-initialized, previous warm; everything else disposed) — TikTok-feel instead of spinner-per-swipe
- Feed videos: thumbnail + `visibility_detector` autoplay; full player on tap
- DB load stays small (~50–100 QPS peak for metadata) — one mid-tier Postgres with the schema's keyset indexes handles it; Supavisor pooling is on by default; read replicas are the escape hatch we won't need soon

### Failure handling
- Upload dies mid-way → TUS resumes; `media_assets` rows stuck in `pending`/`uploading` > 24 h are garbage-collected by a `pg_cron` job (deletes Bunny object too)
- Encode fails → webhook sets `failed`, client shows retry, post never goes live half-broken
- Webhook missed → `pg_cron` reconciliation polls Bunny for `processing` rows older than 15 min

---

## 5. Risks

| Risk | Mitigation |
|---|---|
| FlutterFlow regeneration overwriting hand-written data layer | Treat this repo as the source of truth post-export; stop regenerating from FF (decision needed) |
| Auth import edge cases (unverified emails, Apple private-relay addresses) | Rehearse on staging export; keep Firebase Auth live until parity verified |
| ETL data drift during long migration | Idempotent re-runnable ETL + final freeze-window delta pass |
| Old app versions writing to Firebase post-cutover | Force-update gate (already common in consumer apps); Firebase flipped read-only |
| Legacy media URLs in old posts | `legacy_*_url` columns + Bunny pull zone keep them rendering; backfill job migrates in background |
