# GymFeed AI Developer Handoff

Last updated: 2026-08-16 (Europe/Belgrade)

This is the current engineering handoff for the GymFeed mobile and web app. It
summarizes the work implemented in this workspace, the intended product
behavior, the external configuration already performed, the deployment paths,
and the remaining risks. A future developer or AI agent should read this file
before editing the project.

> **Critical repository warning:** this working directory contains a large,
> valuable, uncommitted migration and feature set. Do not run `git reset`,
> `git checkout -- .`, `git clean`, or an automatic rebase/pull. Preserve the
> working tree and inspect `git status` before every task.

## 1. Product model and terminology

GymFeed has two distinct product areas:

- **Home / GymFeed** is the social feed: posts, food posts, stories, likes,
  comments, sharing, follows, notifications, profiles, and messages.
- **Coach** is the training and nutrition product. Its top switch contains
  **Coach**, **Train**, and **Events**. Coach includes Scan food, Scan equipment,
  AI Trainer, Body scan, Nutrition diary, and My Progress & plans.
- The bottom navigation is **Home / Explore / Coach / FitClips / Profile**. The
  center Coach item is the training hub, not a generic `+` action.
- A feed `+` action may still create social content. It is not the old unused
  Train FAB.

Primary visual language: black/dark surfaces, bright GymFeed green, rounded
cards/pills, Poppins typography, and mobile-first layouts. Flutter web wraps the
same routed pages in a desktop shell with persistent navigation and wider
content columns.

## 2. Repository and release identity

| Item | Value |
|---|---|
| Repository | `https://github.com/Alex43515/GymFeed.git` |
| Local branch | `main` |
| Flutter app package | `com.flutterflow.gymfeedofficial` |
| Flutter/Dart | Flutter `3.27.4`, Dart `3.6.2` |
| App version in `pubspec.yaml` | `2.1.20+190` |
| Minimum Android SDK | 24 |
| Android compile/target SDK | 36 |
| Production web origin | `https://gymfeed.io` |
| Supabase project ref | `bzinwojowkxavfzilvat` |
| Google Cloud project | `gym-feed-official-27tdk3` |
| RevenueCat entitlement | `premium_features` |

The app started as a FlutterFlow export. This repository is now the source of
truth. Regenerating the project from FlutterFlow can overwrite hand-written
repositories, auth, media, Coach, web, and routing code.

### Working-tree state at handoff creation

At the time this document was written:

- Local HEAD: `09142f212b3027ee50e1e70f3ce320466bdb933a`
- Recorded `origin/main`: `a49bcd38b6afe4c7456178ed82c9e9ee2bb638f3`
- Local `main` reported **ahead 6, behind 2**.
- There were approximately **141 modified tracked files** and hundreds of
  untracked files/path entries containing the Supabase migration, tests,
  workflows, and new feature code.

Do not assume the remote repository contains everything described below. Make a
backup branch or archive first, exclude temporary `.codex-*`, build artifacts,
downloaded credentials, and `scripts/.env`, then reconcile the divergent Git
history deliberately through a reviewed branch/PR.

## 3. Technology architecture

### Client

- Flutter/FlutterFlow-generated UI with hand-written Dart feature layers.
- `go_router` for navigation.
- `supabase_flutter` with PKCE auth and persisted sessions.
- `infinite_scroll_pagination` for feed pagination.
- `video_player`/Chewie plus custom GymFeed controls and HLS web support.
- `video_compress` and `flutter_image_compress` for upload preparation.
- `purchases_flutter` for RevenueCat.
- `firebase_messaging` plus `flutter_local_notifications` only for mobile push
  transport and audible foreground display.

### Backend

- Supabase Auth, Postgres, Row Level Security, Storage, Realtime, RPCs, Edge
  Functions, and cron/database webhooks.
- Bunny Stream for new production video uploads, transcoding, thumbnails, and
  HLS delivery.
- OpenAI as the primary AI provider for plans, Coach, food, equipment, and body
  analysis where configured; Gemini is the fallback.
- RevenueCat remains the subscription source of truth.
- Firebase/Google FCM remains the push delivery network. Supabase owns the app
  data and push queue; using FCM does **not** mean Firestore is the backend.

### Important source directories

| Path | Responsibility |
|---|---|
| `lib/backend/supabase/` | Supabase bootstrap, typed models, AI service, repositories |
| `lib/auth/supabase_auth/` | Email, password recovery, OAuth, callbacks, user provider |
| `lib/ai_workout/` | Coach hub, premium UI, scanners, diary, starter plan |
| `lib/workout/routines/` | Editable routines, sets/reps/kg, history, calendar store |
| `lib/pages/core_pages/` | Feed, Explore, profiles, story UI |
| `lib/pages/messages/` | Inbox, new conversation, thread, media pipeline |
| `lib/pages/posts/` | Create/edit/render posts and food posts |
| `lib/custom_code/actions/` | Media selection, compression, Bunny upload, sharing |
| `lib/custom_code/widgets/` | Video players/controls, splash, upload progress |
| `lib/web/` | Desktop web application shell |
| `supabase/migrations/` | Ordered database schema/RLS/function changes |
| `supabase/functions/` | AI, media, push, share, RevenueCat Edge Functions |
| `website/public_html/` | Namecheap-only PHP, App Links, legal pages, `.htaccess` |
| `.github/workflows/` | Website, Google Play internal, and iOS/TestFlight automation |
| `test/`, `integration_test/` | Unit/widget/integration regression coverage |

The public Supabase URL and publishable/anon key in the Flutter client are
expected to be public. Security must come from RLS. Never ship a service-role
key, AI provider key, Bunny API key, SMTP password, signing key, or Play service
account in the app or repository.

## 4. Implemented product areas

### 4.1 Authentication and onboarding

- Supabase email/password authentication replaces the primary Firebase auth
  path while keeping provider-agnostic compatibility shims for generated code.
- The splash screen remains intentionally visible for its designed duration.
- Auth routing no longer sends a successful login back to the initial
  login/signup chooser.
- Email confirmation is enabled. A pending signup is not treated as logged in.
- Verification links return to:
  - Web: `https://gymfeed.io/emailVerification`
  - Native: `com.flutterflow.gymfeedofficial://emailVerification`
- Password reset links return to:
  - Web: `https://gymfeed.io/changePassword`
  - Native: `com.flutterflow.gymfeedofficial://changePassword`
- Reset-password validation requires at least eight characters, a letter, a
  number, and matching confirmation.
- Google OAuth is implemented through Supabase PKCE for sign-in and signup.
- Google signup can be launched from an empty Register Account form. Verified
  Google name/email are used and a unique safe username is generated if the
  user did not enter one.
- Social callbacks only accept allow-listed destinations (`/feed` or
  `/allMostDone`) to prevent open redirects.
- The final onboarding page explains that GymFeed is building a personalized
  28-day workout and meal plan, shows progress, and then hands off to the ready
  plan flow.

#### Google OAuth live configuration

Google Cloud OAuth client **GymFeed Supabase Web** must contain:

```text
Authorized JavaScript origins:
https://gymfeed.io
https://www.gymfeed.io

Authorized redirect URI:
https://bzinwojowkxavfzilvat.supabase.co/auth/v1/callback
```

Supabase Authentication -> Google must use that web client ID and secret.
`supabase/config.toml` contains the website, custom app scheme, and localhost
redirect allow-list. On 2026-08-16 the real authorization URL was tested and
reached Google's account chooser without `redirect_uri_mismatch`.

Apple and Facebook buttons exist in code, but they are not production-ready
until their Supabase providers and external developer credentials are enabled.
The Apple Developer membership was not current at the time of this handoff.

#### Email delivery

- Supabase `Confirm email` is enabled.
- Production sender mailbox: `official@gymfeed.io` on Namecheap Private Email.
- Domain MX was changed to `mx1.privateemail.com` and `mx2.privateemail.com`;
  cPanel Email Routing should remain **Remote Mail Exchanger**.
- Supabase custom SMTP is configured outside the repository. Do not confuse the
  cPanel system mailbox `gymfoflo@gymfeed.io` with the Private Email mailbox.
- SPF, DKIM, and DMARC must remain valid. Run an actual new-user verification
  and password-reset delivery test after any DNS or SMTP change.

### 4.2 Personalized 28-day starter plan

- Signup answers are saved into user metadata before email verification and
  persisted to public/private profile tables after a real verified session.
- `starter_plans` stores generation status, period, normalized JSON, raw
  provider results, errors, and timestamps.
- The generator creates four dated weeks of workouts and 28 days of meals.
- Workouts contain exercises with explicit per-set reps and kilograms.
- Nutrition includes daily calories/macros and meal descriptions.
- Deterministic validation checks weekly workout coverage, all 28 meal days,
  numeric bounds, and allergies before accepting provider output.
- OpenAI (`gpt-4o-mini` through the default AI service) is primary; Gemini
  `gemini-3.5-flash-lite` is fallback and also performs allergy repair.
- Ready workouts are imported into Train; planned meals appear in Nutrition
  diary and are clickable to a detail/preparation screen.
- Plan generation is idempotent unless explicitly forced. Timeouts move to a
  retry/deferred state instead of leaving onboarding permanently stuck.

### 4.3 Coach hub and premium access

- Coach hub matches the Coach / Train / Events top-pill design.
- Coach tools: Scan food, Scan equipment, AI Trainer, Body scan, Nutrition
  diary, and My Progress & plans.
- Free users share **three** trial AI uses across food scans, equipment scans,
  and AI Trainer messages.
- `AiUsageGate.claimUse()` uses a compare-and-swap update on
  `profile_private.button_click`; failed provider calls refund the use.
- At zero remaining uses, the upgrade path opens the RevenueCat premium page.
- RevenueCat entitlement ID: `premium_features`.
- A UID-only internal override currently grants premium to
  `a9fd1bc3-61a8-43a0-b96e-b6e7f0c6d060`. Do not add email-based overrides.
- The RevenueCat webhook records trusted subscription lifecycle outcomes and
  marketing attribution. Client-submitted purchase events are not trusted.
- RevenueCat is not supported in Flutter web by the current client utility;
  premium purchase/restore must be completed in a supported mobile build.

### 4.4 AI Coach

- The Coach loads private profile data, current starter plan, editable routines,
  a dated 14-day Train calendar, recent workout history, recent meals, and
  progress measurements before responding.
- It stores conversation messages and rolling memory in `ai_coach_threads` and
  `ai_coach_messages`.
- It answers only fitness, gym, recovery, meals, calories/macros, and nutrition
  questions. Out-of-scope requests receive a fixed refusal.
- A canonical health disclosure is appended by the application.
- The dated Train calendar is authoritative. The AI must say no workout is
  scheduled when a day is empty; it must not substitute an old/random workout.
- If the weekly target is already met, it recommends rest. If the user is below
  target and a safe saved routine exists, it proposes a workout.
- Workout creation uses a private structured action (`schedule_workout`) and an
  explicit **Implement** action. Only after the Train write succeeds does the
  conversation record “Done”. Skip makes no calendar change.
- Coach/action primary model: `gpt-5-mini` with low reasoning.
- Fallback order: `gemini-3.6-flash`, then `gemini-3.5-flash-lite`.

### 4.5 Food, equipment, body scanning, and Nutrition diary

- AI calls go through the authenticated `ai-proxy`; provider secrets never
  enter the client.
- Food primary vision model: `gpt-4o-mini`.
- Equipment primary vision model: `gpt-5.4-mini`, high image detail, medium
  reasoning. This was upgraded because smaller vision models misidentified
  machines.
- Vision fallback: `gemini-3.5-flash-lite`.
- Scanner output is normalized and validated before persistence. Provider/model
  metadata is retained for diagnostics.
- Food scans map to the current user in `meal_scans` and include calories,
  protein, carbs, fat, portion, ingredients, source image, and scan timestamp.
- Nutrition diary supports past/future dates, daily kcal and macro goals,
  progress bars, scanned/logged meals, AI planned meals, logging a planned meal,
  and meal detail/preparation screens.
- Body scan reports use the legacy report metric set (weight, body fat, BMI,
  lean/fat distribution and related measurements) through the Supabase-backed
  body scan repository. Real-device full-body framing and provider reliability
  must continue to be regression tested.

### 4.6 Train, routines, calendar, and Events

- Train supports date selection in the past and future.
- Routines can be created, opened, previewed, started, edited, scheduled,
  unscheduled, and deleted.
- Each exercise exposes editable per-set reps and kg before and during a
  workout. Sets and exercises can be added and removed.
- Completed workouts save history and update last-performed state.
- AI starter-plan routines are materialized into Train without overwriting
  later user edits for the same plan version.
- Events search and clickable training flows were repaired.
- The unused Train floating `+` button was removed where the new routine action
  replaced it.

> **Known architectural limitation:** `WorkoutRoutineStore` currently persists
> routines, schedules, and workout history in user-scoped `SharedPreferences`.
> It is not cross-device and does not synchronize with the web session. The
> starter plan itself is in Supabase, but user edits and AI-added calendar items
> are local. Moving this store to Supabase is a high-priority production task.

### 4.7 Progress

- My Progress & plans moved from the Profile level icon into Coach below the
  Nutrition diary.
- Weight and body-fat values are editable and visually aligned with their units.
- Activity frequency/session duration and workout level are shown.
- Workout and meal plan cards route directly to Train and Nutrition diary
  instead of rendering raw plan JSON.
- Monthly progress entries are stored in `progress_entries`, support photos,
  weight, body-fat percentage, notes, editing, and deletion.

### 4.8 Social feed, profiles, likes, comments, and owner actions

- The Home feed uses Supabase pagination and stable item identity to prevent the
  upward-scroll jump/reset bug.
- Like uses the flexing-arm visual and real database counts. Comments use real
  counts and Supabase rows.
- Feed/profile posts render only the requested author's content; the old bug
  showing every post on every profile was removed.
- Follow/unfollow, follower/following lists and counters use Supabase `follows`.
- Edit profile writes to Supabase and refreshes visible profile state.
- Owner actions support edit, disable/enable likes, disable/enable comments,
  and delete. Migration `0023` enforces these permissions server-side.
- Duplicate share buttons were removed from post detail.
- Food posts use the same dark upload state design and media pipeline as other
  posts rather than legacy white boxes/GIF-like previews.
- Social notification types and counters are database driven.

### 4.9 Video and image pipeline

- Images upload to the public Supabase `images` bucket under user-owned paths.
- New videos are prepared/compressed on native clients, then uploaded directly
  to Bunny Stream through a backend-issued TUS ticket.
- Web reads browser-selected video bytes directly; native uses the shared
  compression boundary.
- `create-upload` creates `media_assets` and returns Bunny upload credentials.
- `media-webhook` marks encoding status and exposes HLS/thumbnail URLs.
- Feed, post detail, food post, story, messaging, and training uploads reuse the
  shared preparation/upload rules. Chat video preparation has its own testable
  wrapper over the same compressor.
- The custom player exposes centered play/pause, mute, time, and a seekable
  progress bar. Reels use full-page media with the bottom nav present.
- Migration `0024` reconciles the feed playback URL so legacy Supabase-hosted
  MP4s and Bunny HLS both display correctly.

Operational behavior: a newly uploaded Bunny video may show its poster while
`media_assets.status` is `processing`; it should become playable when the Bunny
webhook marks it `ready`. Never store an animated preview/GIF as the canonical
video URL.

**Still required before declaring media fully production-ready:** perform a
real-device upload matrix for regular post video, food-post video, story video,
message video, workout cover/video, feed playback, post detail, Reels, profile
grid, and Flutter web. Verify both portrait and landscape sources and wait for
webhook completion.

### 4.10 Stories

- “Add to your gym day” sheet includes camera, gallery, recent media, avatar
  ring, and 24-hour behavior.
- Photo/video stories persist to Supabase with ownership and expiry.
- Story visibility respects follow/block rules.
- Views are recorded without duplicate viewers and owner/viewer RLS is applied.

### 4.11 Messaging

- Messages list, active users, search, new message, and individual threads were
  redesigned against Supabase repositories.
- Chats and messages support Realtime updates and read markers.
- Users can send text, images, videos, shared workouts, shared meals/posts, and
  message reactions where the UI exposes them.
- Video messages go through mandatory compression/preparation before upload.

### 4.12 Sharing and app links

- Internal sharing uses multi-select recipients and sends through GymFeed
  messaging.
- External sharing uses canonical links:
  `https://gymfeed.io/post/<post-uuid>`.
- Namecheap `.htaccess` routes public post links through `post.php`, which asks
  the public `share-post` Edge Function for crawlable Open Graph metadata.
- The public page offers app opening and a Flutter web fallback.
- Android App Links verify `gymfeed.io` through
  `website/public_html/.well-known/assetlinks.json`.
- Native custom deep link format:
  `com.flutterflow.gymfeedofficial:/postDetails?post=<uuid>`.
- iOS Universal Links remain a later task after Apple Developer membership and
  the final App Store identity are restored.

### 4.13 Notifications and audible push

- Social notification rows are generated by trusted database triggers for
  follows, likes, and comments.
- Migration `0022` removes legacy duplicate triggers, deletes old duplicates,
  canonicalizes types, and adds same-transaction idempotency protection.
- Chat and social events enqueue trusted `push_queue` jobs.
- `push-worker` claims queued jobs and calls FCM HTTP v1 with a Google/Firebase
  service account stored only as an Edge Function secret.
- Mobile registration stores FCM tokens through the `register_fcm_token` RPC.
- Android uses the new immutable audible channel `gymfeed_alerts_v2` with max
  importance, sound, and vibration. Foreground Android pushes are rendered as
  local notifications; background payloads are rendered by the OS.
- iOS payloads request alert, badge, and default sound, but iOS production
  delivery still needs current Apple/APNs credentials and a real-device test.

FCM is intentionally retained as transport. The application does not need
Firestore for this and normal FCM delivery does not require a separate paid
Firebase database.

### 4.14 Desktop web app

- `gymfeed.io` serves a Flutter web build of the real app, not a parking page.
- `DesktopAppShell` supplies left navigation, content canvas, and right-side
  actions while routed pages remain shared with mobile.
- Sidebar routes, messages, notifications, profile, Coach, Train, FitClips, and
  quick actions are wired through GoRouter.
- Desktop text-decoration overrides remove the accidental yellow underlines.
- Profile has a dedicated desktop layout instead of stretching the phone view.
- Legal/support pages and share PHP are preserved outside generated Flutter
  output during deployment.

## 5. Supabase migrations

Apply migrations in numeric order. The owner reported applying all migration
files through `0024`; a future agent should still confirm the remote migration
history before assuming parity.

| Migration | Purpose |
|---|---|
| `0001_initial_schema.sql` | Core profiles/private data, posts, media, stories, follows, chats, notifications, workouts, trainings, meals, FCM queue, triggers, RLS, feed RPC |
| `0002_advisor_hardening.sql` | Missing indexes and function-execution hardening |
| `0003_lock_function_execute.sql` | Locks privileged helper execution further |
| `0004_profile_parity_fields.sql` | Adds fields needed to match the legacy user/profile model |
| `0005_cron_jobs.sql` | Media cleanup/reconciliation and scheduled backend work |
| `0006_storage_images_bucket.sql` | Public images bucket plus owner path policies |
| `0007_feed_relevance.sql` | Following-aware/paginated `feed_page()` behavior |
| `0008_reels_page.sql` | Paginated Reels RPC |
| `0009_videos_bucket.sql` | Video bucket and owner policies for legacy/direct video assets |
| `0010_feed_post_permissions.sql` | Feed shape and post permission fields |
| `0011_reconcile_social_counts.sql` | Repairs denormalized social counters |
| `0012_messaging_read_receipts.sql` | Chat read markers and last-message updates |
| `0013_progress_tracking.sql` | Monthly progress table and owner RLS |
| `0014_coach_and_media_hardening.sql` | Coach activity log and Reels/media hardening |
| `0015_story_feature_hardening.sql` | Story visibility, viewer policies, and indexes |
| `0016_social_notifications.sql` | Follow/like/comment notification triggers |
| `0017_marketing_automation.sql` | First-party marketing runs, content, attribution, events, budgets, learnings |
| `0018_starter_plans.sql` | Personalized 28-day plan persistence and RLS |
| `0019_ai_coach_memory.sql` | Coach threads, messages, rolling memory, RLS |
| `0020_video_asset_reconciliation.sql` | Reconciles legacy/new video asset metadata |
| `0021_push_notifications.sql` | Token RPC, push claiming, social/chat enqueue, worker wakeup |
| `0022_notification_idempotency.sql` | Removes duplicate notifications and prevents duplicate pushes |
| `0023_enforce_post_interaction_permissions.sql` | Enforces disabled likes/comments and owner post controls |
| `0024_feed_video_playback_url.sql` | Returns the correct canonical playback URL in the feed |

Row Level Security is part of the feature implementation. Do not “fix” a client
failure by weakening RLS globally. Repair the specific policy/RPC and add a
regression test.

## 6. Edge Functions and required secrets

| Function | Responsibility | JWT |
|---|---|---|
| `ai-proxy` | Authenticated OpenAI/Gemini proxy; keeps keys server-side | Required |
| `create-upload` | Authenticates user, rate limits, creates Bunny TUS upload ticket/media row | Required |
| `media-webhook` | Receives Bunny encoding events, reconciles media state | Provider webhook |
| `push-worker` | Claims trusted push queue and delivers through FCM HTTP v1 | Public wake endpoint; no caller-controlled recipients |
| `share-post` | Public HTML/Open Graph response for a post UUID | Disabled (`verify_jwt=false`) |
| `revenuecat-webhook` | Verifies RevenueCat auth header and records subscription events | Provider webhook |

Expected Supabase secrets (names only; never put values in this document):

```text
OPENAI_API_KEY
GEMINI_API_KEY
BUNNY_STREAM_LIBRARY_ID
BUNNY_STREAM_CDN_HOST
BUNNY_STREAM_API_KEY
BUNNY_WEBHOOK_SECRET
DAILY_VIDEO_LIMIT
FIREBASE_SERVICE_ACCOUNT_JSON
PUBLIC_SITE_URL
REVENUECAT_WEBHOOK_AUTH
MARKETING_SUPABASE_SECRET_KEY   # optional dedicated backend key
```

Supabase automatically provides `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
`SUPABASE_SERVICE_ROLE_KEY` in supported Edge Function environments. Service
role use must remain server-only.

Typical deployment commands:

```powershell
supabase link --project-ref bzinwojowkxavfzilvat
supabase migration list
supabase db push
supabase functions deploy ai-proxy
supabase functions deploy create-upload
supabase functions deploy media-webhook --no-verify-jwt
supabase functions deploy push-worker --no-verify-jwt
supabase functions deploy share-post --no-verify-jwt
supabase functions deploy revenuecat-webhook --no-verify-jwt
```

Check each function’s intended JWT mode before deployment; do not copy
`--no-verify-jwt` to authenticated user functions.

## 7. Website hosting and automation

Hosting is Namecheap Stellar/cPanel:

- SSH host: `server272.web-hosting.com`
- cPanel/SSH user: `gymfoflo`
- Expected deployment path: `/home/gymfoflo/public_html`
- SSH port: `21098`

`.github/workflows/deploy-website.yml` runs on `main` changes to app/web assets,
tests the project, builds Flutter web, assembles Namecheap-specific files, rsyncs
through SSH, and verifies production URLs.

Required GitHub environment/secrets:

```text
Environment: production
NAMECHEAP_SSH_HOST
NAMECHEAP_SSH_USER
NAMECHEAP_SSH_PRIVATE_KEY
NAMECHEAP_SSH_KNOWN_HOSTS
NAMECHEAP_DEPLOY_PATH
```

The assembly step intentionally preserves/adds:

- `website/public_html/.htaccess`
- `website/public_html/post.php`
- `.well-known/assetlinks.json`
- static `assets/`
- `privacy/`, `terms/`, and `support/`

Never upload a raw mobile-sized mockup as the website. Build the Flutter web
app so `DesktopAppShell` is active on desktop breakpoints.

## 8. Android build and Google Play automation

This is a Flutter project, not React Native. **Expo Go is not part of the build
or release process.**

Local build commands:

```powershell
Set-Location "C:\Users\My SM PC\Desktop\gym_feed (12)\gym_feed (1)\gym_feed (23)\gym_feed"
flutter pub get
flutter test
flutter build apk --release
flutter build appbundle --release
```

Artifacts:

```text
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

`android/app/build.gradle` reads signing from `key.properties` locally or these
environment variables in CI:

```text
ANDROID_KEYSTORE_PATH
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
ANDROID_STORE_PASSWORD
```

`.github/workflows/deploy-android-internal.yml` runs tests, allocates the next
Play version code, signs an AAB, verifies the registered upload certificate,
uploads an artifact, and publishes to the Google Play **internal** track.

Required GitHub environment/secrets:

```text
Environment: google-play-internal
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
ANDROID_UPLOAD_KEYSTORE_BASE64
ANDROID_UPLOAD_KEY_ALIAS
ANDROID_UPLOAD_KEY_PASSWORD
ANDROID_UPLOAD_STORE_PASSWORD
```

The workflow pins Flutter `3.27.4`, Java 17, Android API/build tools 36, package
`com.flutterflow.gymfeedofficial`, and verifies upload certificate SHA-256
`C07A8D59F8F5265F622053BFCDE9F2D7D0C55566E54BE49B8B226420536BD506`.

An existing APK/AAB in `build/` may predate the latest uncommitted changes.
Always rebuild after auth/media/UI changes and report the generated artifact's
timestamp and SHA-256.

### iOS validation and TestFlight automation

`.github/workflows/deploy-ios-testflight.yml` uses a GitHub-hosted `macos-26`
runner. Relevant `main` changes run tests and build an unsigned Simulator app.
A manual run with `publish_to_testflight=true` provisions the main app and
notification extension, builds a signed IPA, stores it as an artifact, and
uploads it to App Store Connect. The signed job requires the protected
`app-store-connect` environment and these secrets:

```text
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_PRIVATE_KEY_BASE64
IOS_DISTRIBUTION_PRIVATE_KEY_BASE64
```

Apple Developer membership must be active. Full credential setup and operating
instructions are in `docs/IOS_AUTOMATION.md`. Expo Go is not involved.

## 9. Test and verification strategy

Fast baseline:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Focused suites currently present:

| Test file | Coverage |
|---|---|
| `social_auth_flow_test.dart` | OAuth redirects, allow-list, cancellation, Google username, callback |
| `email_verification_flow_test.dart` | verification redirects, metadata, confirmation completion |
| `password_recovery_flow_test.dart` | reset redirects and password rules |
| `auth_navigation_test.dart` | login/signup routing guards |
| `signup_plan_handoff_test.dart` | final onboarding generation states |
| `starter_plan_test.dart` | plan normalization, dates, allergies, provider fallback |
| `ai_coach_test.dart` | scope, memory, 14-day truth, proposals, Implement/Skip |
| `coach_vision_test.dart` | food/equipment models, normalization and fallback |
| `body_scan_test.dart` | body scan parsing/metrics/error paths |
| `nutrition_diary_test.dart` | diary totals/goals/planned meals |
| `workout_routine_flow_test.dart` | routine/set editing, calendar/history behavior |
| `profile_post_scope_test.dart` | only an author’s posts appear on that profile |
| `post_owner_actions_test.dart` | edit, interaction toggles, delete ownership |
| `notification_idempotency_test.dart` | duplicate notification migration behavior |
| `messaging_models_test.dart` | chat/thread/media model behavior |
| `story_feature_test.dart` | story expiry, visibility, views, upload behavior |
| `video_pipeline_test.dart` | URL classification, video upload and playback mapping |
| `share_links_test.dart` | canonical links, deep links, public share behavior |
| `desktop_app_shell_test.dart` | desktop navigation/layout behavior |
| `progress_feature_test.dart` | progress entry/edit model behavior |
| `premium_events_test.dart` | free-use and premium UI/event rules |
| `live_premium_e2e_test.dart` | real backend/provider premium checks; needs explicit credentials/network |
| `integration_test/bunny_video_playback_test.dart` | real Bunny playback integration |

Latest verification before this document:

- `flutter test`: **136 passed, 1 skipped, 0 failed** on 2026-08-16.
- `flutter test test/social_auth_flow_test.dart`: **6 passed**.
- `flutter analyze` for the OAuth/signup files: **no issues**.
- A real Supabase -> Google authorization navigation reached the account chooser
  and did not return error 400.

Do not claim a feature is fixed only because it compiles. For Supabase, media,
SMTP, RevenueCat, Google OAuth, and FCM, also perform a live test against the
configured production/staging service.

## 10. Known gaps and priority follow-up

1. **Protect and commit the working tree.** The current branch is divergent and
   the majority of the implemented migration is not safely represented by the
   recorded remote branch.
2. **Move Train’s editable routine/calendar/history store to Supabase.** It is
   currently SharedPreferences and therefore cannot reliably synchronize
   Android and web or survive device replacement.
3. **Run the complete test suite and production build after the latest Google
   signup change.** The existing release artifact may not include it.
4. **Run the full real-device media matrix.** Especially recheck newly uploaded
   food-post and standard-post video playback in the feed after Bunny encoding.
5. **Verify push end to end on two physical accounts/devices.** Confirm exactly
   one audible push for like, comment, follow, and message; confirm token refresh
   and notification tap routing.
6. **Finish iOS production configuration.** The macOS validation/TestFlight
   workflow is present, but Apple Developer membership still needs renewal.
   Configure Apple OAuth and APNs, add `apple-app-site-association`, validate
   Universal Links, and complete a signed physical-device/TestFlight run.
7. **Keep disabled social providers visually honest.** Facebook/Apple should be
   hidden or show a clear “not available” state until credentials are live.
8. **Audit remaining Firebase/Firestore imports.** Some generated models/shims
   remain for compatibility. FCM is intentional; Firestore-backed feature writes
   should not be reintroduced.
9. **Fix source encoding artifacts.** Several inherited comments/UI strings show
   mojibake such as `Â·` or `â€”`. Normalize files to UTF-8 and add a regression
   scan without blindly replacing valid localized text.
10. **Rotate any credential ever placed in chat, logs, downloads, or old source.**
    Keep only GitHub/Supabase secret-store copies.
11. **Refresh stale documents.** `docs/MIGRATION_PLAN.md` still contains early
    “planning/awaiting access” language. Treat this handoff and the current code
    as newer, then update/archive the old plan after the Git history is safe.
12. **Add crash/production observability.** Sentry was proposed but is not shown
    as completed in the current dependency/config inventory.

## 11. Rules for future AI/developer work

- Start with `git status -sb` and inspect overlapping changes before editing.
- Never erase or replace user changes to make a clean diff.
- Use repositories under `lib/backend/supabase/repositories/` instead of adding
  direct scattered database calls to widgets.
- Keep RLS and database triggers authoritative for ownership, counters,
  notification creation, and permissions.
- Keep provider/API secrets in Supabase Edge Function secrets or GitHub Secrets.
- Keep Google/Firebase service-account JSON out of Git.
- Preserve one shared media pipeline. Do not add another page-specific upload
  implementation or store GIF/preview URLs as canonical videos.
- Preserve the distinction between social Home and training Coach.
- Preserve the splash duration unless the product owner explicitly changes it.
- Any AI action that writes user data must be deterministic, explicit, validated,
  and confirmed in the UI. The language model must not claim success before the
  application write succeeds.
- Add or update focused tests with every fix, then run the relevant live flow
  when an external system is involved.
- Do not call the app “Expo” or introduce an Expo deployment path; Android and
  web are built by Flutter.

## 12. Related documentation

- `README.md`
- `docs/MIGRATION_PLAN.md` (historical/stale in parts)
- `docs/MEDIA_ARCHITECTURE.md`
- `docs/WEBSITE_AUTOMATION.md`
- `docs/IOS_AUTOMATION.md`
- `docs/MARKETING_AUTOMATION.md`
- `lib/backend/supabase/README.md`
- `scripts/README.md`
