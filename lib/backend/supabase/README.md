# Supabase data layer (`lib/backend/supabase/`)

Replaces the generated Firestore layer. The app keeps its provider-agnostic auth
abstraction (`lib/auth/base_auth_user_provider.dart`, `auth_manager.dart`); this
package supplies the Supabase implementation plus one repository per domain.

## Layout

```
supabase/
  supabase.dart            # client bootstrap (SupaFlow.initialize, `supabase` getter)
  ai_service.dart          # Gemini + OpenAI via the ai-proxy Edge Function
  database/                # typed row models (plain Dart, mirror old *Record getters)
    profile.dart
    feed_item.dart
  repositories/            # all reads/writes, one per domain
    profile_repository.dart
    post_repository.dart
    media_repository.dart
lib/auth/supabase_auth/    # BaseAuthUser + AuthManager implementations
    supabase_user_provider.dart
    supabase_auth_manager.dart
    auth_util.dart
```

## Conventions (follow these for the remaining repositories)

- A repository gets the current user via `supabase.auth.currentUser?.id` — never
  import `auth_util` (avoids a cycle).
- Reads return typed models from `database/`; writes take named params or a
  snake_case map and target the correct table.
- **Realtime only where liveness matters** (chat messages, notifications, media
  status). Everything else is paginated `select()` / RPC.
- Keyset pagination via `range()` or a `before`-cursor; never fetch whole tables
  (the old reels bug).
- Denormalized counters (`like_count`, `comment_count`) are maintained by DB
  triggers — repositories only insert/delete the join rows.

## Status

**Done (this pass):** client bootstrap · Supabase auth (email/password; Google &
Apple stubbed pending provider config) · Profile model + repository (incl.
follow/block/search) · feed/post repository (via `feed_page()` RPC) + FeedItem ·
media repository (create-upload ticket, image upload, `media_assets` Realtime) ·
AI service (ai-proxy) · comment repository · story repository · chat repository
(Realtime messages) · notification repository (Realtime) · training repository
(reels feed + likes + participation) · workout repository (entries + exercise
sessions) · meal repository (AI scans + daily macro totals) · bookmark repository
(post/food_post/training via `kind` enum) · search repository (recent history +
profile/post search).

**Phase 3 cutover — COMPLETE**

| Work item | Status |
|---|---|
| `tus_client_plus` pubspec + `upload_video_to_bunny` custom action | ✅ |
| `main.dart` — Supabase boot + `gymFeedSupabaseUserStream()` | ✅ |
| `firebase_auth/auth_util.dart` shim — re-exports Supabase symbols | ✅ |
| `currentUserDocument` aliased to `currentUserProfile` | ✅ |
| `gemini.dart` → `AiService` (ai-proxy) | ✅ |
| `api_calls.dart` — all OpenAI calls route through ai-proxy | ✅ |
| Hardcoded OpenAI key zeroed from `FFAppState` | ✅ |
| `push_notifications_util.dart` compile fix (`.uid` not `.reference.path`) | ✅ |
| `supabase/migrations/0005_cron_jobs.sql` — pg_cron GC + reconciler | ✅ |

**Compile status:** `flutter pub get` + `flutter analyze` both pass — **0 errors**
(Flutter 3.27.4 / Dart 3.6.2). Remaining analyzer output is pre-existing
FlutterFlow-generated warnings/infos (unused locals in generated widgets,
deprecated Firebase Dynamic Links), none from the migration.

**Pending (next sprint)**

- Rotate exposed credentials: Bunny API key, old Gemini key, old OpenAI key.
- Register Bunny webhook in Bunny Stream dashboard.
- Per-screen migration: Firestore `StreamBuilder` → Supabase repository calls.
  Until each screen is migrated, `Profile.following/unreadNotifications/chats/
  trainingsJoined/userBlocked` return empty lists (widgets render empty state).
- `push-worker` Edge Function (FCM fan-out via Supabase queue).
```
