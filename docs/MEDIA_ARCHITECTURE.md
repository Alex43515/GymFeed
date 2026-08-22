# GymFeed — Media Upload & Delivery Architecture

Status: **design, ready to implement**. Owner-facing design doc for how photo and
video move through GymFeed at 100k+ users. Written to match how professional
UGC-video apps actually build this (Mux, Cloudflare, Supabase reference stacks),
adapted to our Flutter client + Supabase backend + Bunny CDN.

---

## 1. Goals & constraints

| Constraint | Implication |
|---|---|
| 100k+ registered (~30k DAU), reels-style feed | Delivery bandwidth, not upload count, is the scaling problem |
| Mobile, often flaky gym Wi-Fi / cellular | Uploads must be **resumable** and survive app backgrounding |
| Cost sensitivity | Egress is the dominant bill — origin must never serve bytes at scale |
| It's UGC (public video) | Needs a **moderation gate** before content goes public |
| Must match current behavior | Reels autoplay, feed thumbnails, stories — no UX regression |
| Small team | Middleware must be **serverless / zero-ops** |

The current app uploads full progressive MP4s through the Firebase SDK, compresses
on-device (four near-duplicate `video_compress` code paths), and the reels screen
streams the **entire** `userTrainings` collection with no pagination. Every one of
those is a scale bug; this design replaces all of them.

---

## 2. How the pros do it (reference patterns)

We are not inventing anything here — this is the consensus pattern across the
industry, which is exactly why it's the safe choice:

- **Presigned, resumable, direct-to-provider uploads.** The client uploads bytes
  *straight to the video provider's ingest endpoint* using the **TUS** resumable
  protocol, authorized by a short-lived signature your backend generates. Your API
  never receives the file bytes. Bunny, Cloudflare Stream, and Mux all implement
  this same shape. ([Bunny TUS docs](https://bunny.net/docs/stream/tus-resumable-uploads),
  [Mux best-APIs writeup](https://www.mux.com/articles/the-best-video-apis-right-now))
- **Server-side transcoding to an adaptive (ABR) HLS ladder.** You never trust the
  device's encoder. The provider transcodes one uploaded file into 240p–1080p
  renditions + poster + preview, and the player picks a rung based on bandwidth.
- **Webhook-driven "ready" lifecycle.** The provider fires a webhook when encoding
  finishes; a small edge function flips the asset to `ready`. This is the exact
  `@mux/supabase` integration shape — an edge function at `/functions/media-webhook`
  reacting to `video.asset.ready`. ([Mux × Supabase](https://www.mux.com/blog/introducing-mux-supabase-because-every-app-needs-a-database),
  [Supabase DB webhooks](https://supabase.com/docs/guides/functions))
- **Hold-then-publish moderation.** The asset starts **private** and only becomes
  public if moderation passes — not publish-first-review-later. Results route to
  three tiers: auto-approve / human-review / auto-reject, and reviewers see only the
  flagged timestamps, not whole videos. This is Mux Robots' recommended design and
  the same cascade TikTok-scale systems use. ([Mux UGC moderation](https://www.mux.com/articles/ai-content-moderation-ugc-video-pipeline-mux-robots))

---

## 3. Provider comparison

Delivery model matters more than sticker rate. For **short-form video with high view
counts**, flat per-GB egress wins; per-minute-viewed billing is a trap.

| Provider | Billing model | Est. @ ~150 TB/mo delivery | Ops | Verdict |
|---|---|---|---|---|
| **Bunny Stream** | Cheap flat per-GB egress + small encode/storage | **~$1.5k/mo** | Zero | ✅ **Recommended** — cheapest low-effort path, already our image CDN |
| Cloudflare Stream | Per **minute delivered** ($1/1000 min) | Tens of $k/mo at high views | Zero | ❌ Model punishes high-view reels |
| Mux | Premium per-min encode + deliver | Highest | Zero | Best analytics/docs, but cost-prohibitive at our scale |
| api.video / Gumlet | Mid-tier per-min | Mid–high | Zero | No cost win over Bunny |
| **Cloudflare R2 + own HLS pipeline** | **$0 egress** + storage + self-run transcode | Cheapest at massive scale | **High** | ⏳ Escape hatch for 500k+ users only |

**Decision: Bunny Stream for video, Supabase Storage + Bunny pull zone for images.**
R2 + a self-managed pipeline is the documented fallback if egress ever dominates the
bill; it is deliberately *not* built now because it trades a large ops burden for
savings we don't yet need.

---

## 4. Target architecture

### 4.1 Core principle — bytes never touch our middleware

The four edge functions are **control-plane only**: they issue permissions and react
to events. The data plane goes client ↔ provider directly. Anything that proxies
100 MB uploads through an API server becomes the bottleneck and the cost sink.

```
VIDEO UPLOAD
 Flutter ──1. POST /create-upload (JWT)──▶ create-upload (edge fn)
                                           │ auth ✓ · daily quota ✓
                                           │ INSERT media_assets(status=pending)
                                           │ Bunny: POST /library/{lib}/videos → videoId
                                           │ sign: SHA256(lib+key+expire+videoId)
          ◀─2. {videoId, tus headers}──────┘
 Flutter ──3. TUS resumable PUT (direct)──▶ Bunny Stream ingest
                                            │ transcode → HLS 240p…1080p
                                            │ + poster + animated preview
 media-webhook ◀─4. VideoEncoded ──────────┘
   │ verify signature → media_assets.status='processing'→ run moderation
   │ pass → status='ready', asset public → post visible (Realtime notifies author)
   │ fail → status='quarantined' → human review queue

PLAYBACK
 Flutter ──HLS (video_player, native)──▶ Bunny CDN edge (~119 PoPs) → 99% cache hit
```

### 4.2 Video upload — exact Bunny flow

`create-upload` edge function (server-side, key never shipped):

1. Authenticate the caller's Supabase JWT; enforce a per-user daily upload quota
   (counter on `media_assets`).
2. `POST https://video.bunnycdn.com/library/{libraryId}/videos` with `{title}` →
   returns `videoId` (GUID).
3. `expire = now + 3600` (Unix seconds).
4. `signature = SHA256(libraryId + apiKey + expire + videoId)` (hex).
5. `INSERT media_assets (owner_id, kind='video', provider='bunny_stream',
   provider_id=videoId, status='pending')`.
6. Return to the client: `videoId`, `libraryId`, `AuthorizationSignature`,
   `AuthorizationExpire`, and the TUS endpoint `https://video.bunnycdn.com/tusupload`.

Client uploads with a TUS library (`tus_client` for Dart), sending headers
`AuthorizationSignature`, `AuthorizationExpire`, `LibraryId`, `VideoId` and metadata
`filetype`, `title`. TUS auto-resumes across network drops and app suspension.

> Signature spec verbatim from Bunny: `SHA256(library_id + api_key + expiration_time + video_id)`,
> expiry ≥ 3600s. Only the **backend** ever holds `apiKey`.

### 4.3 Images

No provider needed — Supabase Storage handles it:

1. Client resizes (`flutter_image_compress`, ≤2048 px, ~85 quality) and computes a
   **blurhash** locally.
2. Client requests a signed upload URL (or uploads directly with its JWT) into the
   `images`/`avatars` bucket at path `⟨auth.uid()⟩/⟨uuid⟩.jpg` — storage RLS enforces
   the folder prefix = caller id.
3. Delivery is fronted by the existing Bunny **pull zone** (`gymfeed.b-cdn.net`) with
   long-TTL immutable cache headers on content-addressed paths.

### 4.4 `media_assets` state machine

Already in the schema (`0001`). One row per asset, tracked live via Realtime so the
UI shows placeholder → spinner → media without polling:

```
pending ──(client starts TUS)──▶ uploading ──(webhook: encoded)──▶ processing
   │                                                                   │
   │                                                        moderation pass │ fail
   └────────── 24h GC (pg_cron) ──────────▶ (deleted)          ready ◀─┘  └─▶ quarantined
```

Carries `blurhash`, `thumbnail_url`, `duration`, `width/height`, `hls_url` so the feed
renders instantly with placeholders and attaches players lazily.

---

## 5. Moderation (hold-then-publish)

UGC video is a legal and brand risk; publishing unscreened content is not an option.

- **Gate on publish.** A video is `processing` (private) until moderation returns.
  Posts referencing a not-`ready` asset are hidden by the feed query.
- **Three-tier routing**, not binary: low scores → auto-approve; ambiguous →
  `quarantined` + human review queue (reviewers jump straight to flagged timestamps);
  high-confidence violations → auto-reject. This is what keeps review sustainable at
  scale. ([Mux Robots](https://www.mux.com/articles/ai-content-moderation-ugc-video-pipeline-mux-robots))
- **Signal source options** (pluggable behind the `media-webhook` function):
  - **Gemini vision** on the poster + sampled frames — cheapest, we already have a
    Gemini key and proxy; good enough to launch.
  - **AWS Rekognition Content Moderation** / **Hive** — higher accuracy, per-frame
    scores; drop-in upgrade when volume justifies the cost.
- Thresholds configurable (default sexual 0.7 / violence 0.8; stricter for any
  under-18 surfaces). Every decision is logged to `reports`/`administrative`.

---

## 6. Playback at scale

- **HLS, native.** `video_player` plays Bunny's HLS directly; the CDN serves the ABR
  ladder, the device picks the rung. No progressive MP4s.
- **Reels — 3-controller window.** Paginated 10/page (kills the current
  whole-collection stream). Keep exactly three players alive: current (playing), next
  (pre-initialized), previous (warm); dispose everything else. This is the
  TikTok-feel fix versus a spinner per swipe.
- **Feed — thumbnail + visibility autoplay.** Show `thumbnail_url` over a `blurhash`
  placeholder; attach the player only when the tile is sufficiently on-screen
  (`visibility_detector`); full-screen player on tap.
- **Optional token auth** on Bunny URLs later if hotlinking/leeching becomes an issue
  — not needed at launch.
- DB load for metadata stays ~50–100 QPS peak; the keyset indexes + Supavisor pooling
  handle it on a mid-tier instance. Read replicas are the escape hatch we won't need
  soon.

---

## 7. Failure handling & lifecycle jobs

Serverless + a couple of `pg_cron` reconcilers make this self-healing:

| Failure | Handling |
|---|---|
| Upload dies mid-transfer | TUS resumes from last byte; nothing to do |
| Rows stuck `pending`/`uploading` > 24h | `pg_cron` GC deletes the row **and** the Bunny object |
| Encode fails | Webhook sets `failed`; client shows retry; post never goes half-live |
| Webhook missed/dropped | `pg_cron` polls Bunny for `processing` rows older than 15 min (reconciliation) |
| Account deletion | `delete-account` edge fn purges Storage + Bunny objects, DB cascades handle rows (closes the current GDPR gap) |

Webhook delivery reliability can be hardened later with a queue (`pgmq`) or an
external gateway (e.g. Hookdeck), but native `pg_net` + a cron reconciler is enough
to launch.

---

## 8. Middleware — the four edge functions

All stateless Deno isolates, autoscaling, nothing to operate:

| Function | Trigger | Job |
|---|---|---|
| `create-upload` | Client `POST` (JWT) | Quota check → Bunny video object → presigned TUS ticket → `media_assets` row |
| `media-webhook` | Bunny `VideoEncoded` (signed) | Verify → `processing` → moderation → `ready`/`quarantined` |
| `push-worker` | `pg_cron` drains `push_queue` | FCM HTTP v1 fan-out (FCM kept post-migration) |
| `ai-proxy` | Client `POST` (JWT) | All Gemini **and** OpenAI calls server-side; keys never in the app |

`ai-proxy` is independent of the media provider decision and ships first — it removes
the OpenAI + Gemini keys currently hardcoded in the client.

---

## 9. Rollout

1. **`ai-proxy`** — stop shipping AI keys (immediate security win). *(You set the
   secrets; I deploy.)*
2. **`create-upload` + `media-webhook`** — once the Bunny Stream **library id + API
   key** exist. Enable `pg_cron`/`pg_net`; add the GC + reconciler jobs.
3. **Flutter media layer** — `tus_client` upload action, `media_assets` Realtime
   subscription, reels 3-controller window, feed thumbnail/blurhash.
4. **Moderation** — Gemini vision to launch; upgrade to Rekognition/Hive on volume.

---

### Sources
- Bunny TUS resumable uploads — https://bunny.net/docs/stream/tus-resumable-uploads
- Mux, "The best video APIs right now" — https://www.mux.com/articles/the-best-video-apis-right-now
- Mux × Supabase integration — https://www.mux.com/blog/introducing-mux-supabase-because-every-app-needs-a-database
- Mux Robots, UGC moderation pipeline — https://www.mux.com/articles/ai-content-moderation-ugc-video-pipeline-mux-robots
- Supabase Edge Functions — https://supabase.com/docs/guides/functions
- SupaVlog reference stack (Supabase + Stream + Hookdeck) — https://hookdeck.com/blog/supavlog-vlog-start-kit-supabase-stream-hookdeck-nextjs
