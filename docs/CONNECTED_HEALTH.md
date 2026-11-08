# GymFeed Connected Health

Implemented 2026-10-13. Base: `origin/main` at `ea47f11`, pulled with
`git pull --ff-only origin main` before implementation. Feature branch:
`codex/connected-health`. This feature has not been deployed to production.

## Product and design decision

The primary entry is **Coach → Connected health**, next to Nutrition diary and
My Progress & plans. There is also a **My Progress → Connected health** entry.
It belongs to private activity/progress, not the social profile, feed or a new
bottom tab. The full screen follows GymFeed's dark surfaces, green accents and
rounded cards. One continuous scroll works on small phones and larger text.

The flow explains the benefit and data use before requesting permissions.
The user can connect, view today or the previous six calendar days, sync manually,
manage permissions and disconnect. Displayed metrics: steps, active kcal and
the latest recorded heart rate with its timestamp. It is explicitly not live
heart-rate streaming. Unsupported devices and missing/update-required Android
providers have dedicated guidance. Empty readings are not fabricated as zeroes.

This connects to Apple Health / Health Connect data, including data shared by
watches. It is not a standalone watchOS/Wear OS application, Bluetooth pairing,
remote workout control or universal support for every brand of watch.

## Audit of the previous implementation

Source inspected without editing:
`C:/Users/My SM PC/Desktop/gym_feed (12)/gym_feed (1)/gym_feed_watch`.

- `lib/custom_code/actions/fetch_wearable_data.dart`: configured `health`,
  requested activity/sensor permissions and fetched the three raw data types.
- `lib/jebemtimater/jebemtimater_widget.dart`: prototype Connect Health screen;
  saved a JSON string to Firestore `users.wearableData`.
- Numeric values were serialized as `HealthValue` objects instead of extracting
  the numeric primitive, so JSON encoding was unreliable.
- Authorization/configuration errors were printed, raw overlapping samples were
  displayed, and there was no production connection/retry/disconnect flow.
- Android declared read and write permissions, including outdated XML permission
  names. The implementation did not need write access.
- The old iOS plist included descriptions, but the inspected project did not
  contain a HealthKit entitlement. A plist description alone is insufficient.

## Architecture and improvements

- `lib/health/device_health_gateway.dart`: native health adapter.
- `lib/health/connected_health_controller.dart`: consent, dates, state, sync,
  concurrency and disconnect. Dependency injection supports deterministic tests.
- `lib/health/connected_health_widget.dart`: page and reusable entry card.
- `/connectedHealth` is an authenticated app route.
- `health: 12.2.1` is pinned with the lockfile. This upgrades the old 12.1 line
  while remaining compatible with Flutter 3.27.4 / Dart 3.6.2. Current health
  13.x requires a newer Dart SDK; upgrading the entire app toolchain was outside
  this feature.
- Every requested permission is explicitly READ. Partial Android permissions
  are checked independently. iOS does not reveal read authorization status;
  no-data is never labelled as proven denial.
- Steps use `getTotalStepsInInterval`; active calories use platform interval
  statistics; heart-rate samples are deduplicated and sorted by measurement time.
  Raw watch/phone step samples are not added together.
- Queries use local midnight and next calendar midnight, including DST changes,
  and stop at current time for today. Refreshes cannot overlap. Read requests
  time out after 25 seconds and can be retried.
- Connection and separate AI-sharing consent are account-scoped booleans saved
  locally. Readings stay in memory by default; optional AI sharing is described
  below. No health cache, public profile or analytics integration. Disconnect
  clears both preferences and page data; OS permissions are revoked separately.
- There is no background worker. A connected page syncs on open, resume or
  manual refresh. Closing it ends automatic reads. Separately consented Coach
  questions may also read today's summary while the app is in use.
- Android uses FlutterFragmentActivity, provider availability checks, a native
  permissions-settings link and an independent scrollable privacy explanation
  for both Android 13 and Android 14+ health permission entry points.
- iOS includes HealthKit capability/entitlement, descriptive plist strings,
  native HealthKit availability checks and an Apple Health permissions link.
- Android minimum SDK changes from 24 to 26 because the compatible health plugin
  requires it. Health Connect itself requires Android 9/API 28 or later. Android
  8 can run GymFeed, but gets an unsupported health-connection message.

## Verification and release requirements

### Optional AI Coach context (2026-10-14, release 3.0.8)

- Branch `codex/health-coach-context`, based on the successful 3.0.7 testing
  release, promoted to `release/3.0.8` after the user approved testing publication.
  No merge/push to main or production application rollout is authorized.
- **Connected health → Use activity in AI Coach** is OFF by default, including
  for previously connected users. Turning it on opens a separate disclosure
  naming Supabase, OpenAI and Google Gemini, the data types, purpose, retention,
  private-history persistence and withdrawal behavior. Cancel does not consent.
- AI Coach has a Manage/status strip linking back to Connected health. Merely
  opening Coach reads only preferences, not health records or OS permissions.
- `health_ai_context.dart` reads a fresh, today-only summary per question after
  both consents and authenticated account match. No permission prompt, background
  task or saved health cache. A six-second timeout prevents slow health reads
  blocking coaching; an expired availability check cannot start a late read.
- AI context contains daily steps, estimated active kcal, latest recorded pulse,
  local date, read time, UTC offset and pulse measurement time. No raw samples,
  source/device IDs, sleep, HRV or invented recovery scores. Null means unknown;
  invalid/future pulse readings and wrong-day snapshots are omitted. Read time
  is not claimed to be the watch's sync time. Pulse is explicitly not live.
- Context is added only to the question's prompt, not `AiCoachContext.toJson()`
  (also used by saved plan tools). Existing authenticated `ai-proxy` supplies
  provider keys server-side; no new tables, permissions or credentials needed.
  OpenAI requests explicitly use `store: false`. This is NOT Zero Data Retention:
  provider processing/abuse-monitoring and platform invocation retention apply.
- Questions and answers while sharing is enabled receive an internal storage
  marker, hidden on display. These private chat turns may quote the readings,
  as disclosed. They are deterministically excluded from rolling-memory input,
  and from future request history when sharing is off. Raw summaries are never
  separately saved to a GymFeed health table. User-approved plans still use the
  existing review/Implement workflow; raw readings are forbidden in plan metadata.
- Turning sharing off stops future request context but does not erase existing
  private history/plans. Disconnect also clears AI consent; reconnecting does
  not re-enable it. Mid-read account changes/revocation discard results.
- In-app privacy, Android permission explanation, iOS purpose string and staged
  website privacy text have been updated together. Before any deployment,
  publish that policy and update Play Health apps/Data safety and Apple App
  Privacy disclosures (the existing declaration describes the local-only build).
  Verify provider data-handling agreements/settings; do not market zero retention.
- Testing deployment 3.0.8 adds a reusable privacy prerequisite to both mobile
  workflows. It publishes ONLY `website/public_html/privacy/index.html`, with a
  recoverable previous-file backup and exact-byte HTTPS verification. It never
  syncs/deletes web app assets or invokes the production web-app workflow.
  Store Health/Data safety/App Privacy verification is tracked separately; do
  not treat a successful build/upload as approval of changed declarations.
- Tests use synthetic data and mocked AI transport only. No real health readings
  are uploaded during verification. Physical-watch AI verification remains a
  separate test on an installed build, with that user's explicit consent.
- Verification: 24 new health/Coach unit and widget tests passed, including the
  complete `ask` pipeline with a mock authenticated database and AI transport
  (consent on, off and revoked before dispatch). Full suite: 292 passed, four
  pre-existing live/backend/device tests skipped. Targeted static analysis,
  iOS plist XML validation, local Android debug compilation and web release
  compilation passed. No new iOS signed build was produced on Windows. The web
  check needed regeneration of stale local Flutter web-entrypoint/plugin-cache
  files; no dependency versions or Google sign-in source were changed.
- References: [Apple privacy/health rules](https://developer.apple.com/app-store/review/guidelines/#privacy),
  [Google Health Connect limited use](https://support.google.com/googleplay/android-developer/answer/9888170),
  [OpenAI API data controls](https://developers.openai.com/api/docs/guides/your-data),
  [Supabase invocation logging](https://supabase.com/docs/guides/functions/logging).

Automated coverage includes optional consent, denial, partial/revoked access,
account separation, reconnect, empty iOS data, failures/retry, disconnect,
concurrent refresh, calendar boundaries, system aggregation, duplicate samples,
invalid numeric readings, UI actions and unsupported platforms.

`integration_test/connected_health_device_test.dart` is a real native-plugin
smoke test for an Android 14+ emulator with Health Connect or an iPhone Simulator.
It verifies provider
availability and renders the connect screen without login/backend writes or
requesting health permissions. It does not simulate a physical watch.

Local verification: 217 unit/widget tests passed (one existing live-backend test
was skipped); static analysis passed; Android debug APK and Flutter web release
build passed; native Health Connect availability/UI smoke passed on API 34;
Android privacy activity opened without an AndroidRuntime crash. iOS validation
is run by `.github/workflows/validate-connected-health.yml` on macOS without
store deployment.

Final iOS validation on October 13, 2026: all validation steps passed in
[GitHub Actions run 38456618081](https://github.com/Alex43515/GymFeed/actions/runs/38456618081)
at commit `6961502`. This includes static analysis, the full unit/widget suite,
the unsigned main iOS Simulator build, matching app/notification-extension
metadata, and installation/execution of the native health availability/UI smoke
test on an iPhone Simulator. The test restores its platform override before
Flutter checks debug invariants. This is not a signed IPA, TestFlight upload or
physical-watch synchronization test.

The user subsequently approved testing deployment. Release `3.0.7` combines
this feature with the newer `release/3.0.6` Coach and billing changes. Only the
release branch is sent to Android internal testing and iOS TestFlight; `main`
and production remain unchanged. The Apple workflow checks/enables HealthKit
on the exact existing App ID before fetching signing profiles, and stops if
the protected credentials cannot access it. It uses the same macos-15/Xcode
26.2 toolchain that passed native health validation.

After merging the newer testing release, the combined local Flutter suite
passed 268 tests with four opt-in live tests skipped; focused health analysis
also passed. Android marketing version is 3.0.7, while the publishing workflow
allocates its next Google Play build code from the live uploaded bundles. iOS
uses the same marketing version with a unique timestamp-based build number.

### Testing deployment follow-up (October 14, 2026)

- Android AAB `3.0.7 (223)` built and passed signature verification in Actions,
  but API edit commits initially returned a health-declaration 403. The existing
  declaration only exposed the legacy ACTIVITY_RECOGNITION/BODY_SENSORS fields.
- The same signed AAB was uploaded through **Internal testing**, release 40,
  and published through that track's own Save and publish flow. Play Console
  explicitly confirmed **Available to internal testers** for 3.0.7 (223).
  Tester opt-in: https://play.google.com/apps/internaltest/4701756315095498192.
- Uploading the bundle exposed the missing READ_STEPS,
  READ_ACTIVE_CALORIES_BURNED and READ_HEART_RATE declaration fields. All three
  were completed with the implemented read-only/local-memory use cases and
  submitted for review. The corrected form then passed the API deployment:
  [run 38532797876](https://github.com/Alex43515/GymFeed/actions/runs/38532797876)
  completed successfully and committed **3.0.7 (224)** to the internal track.
  Play Console independently confirmed **Available to internal testers** for
  build 224 (release 41). Build 224 supersedes the initial manual build 223.
- The unrelated pending production rollout for 3.0.6 (222) was neither
  published, removed, nor returned to draft. The global Publish changes control
  was cancelled. No main push or production deployment was performed.
- iOS network failure while downloading SwiftyGif was retried. The subsequent
  HealthKit lookup errors were fixed and locally verified against the existing
  App ID, as described below.
  The signing job generated a new ACTIVE Runner profile (`2DQTDF4SQP`); its
  signed profile content was read back and confirmed to contain the exact
  existing application identifier and `com.apple.developer.healthkit = true`.
- [iOS deployment run 38530431988](https://github.com/Alex43515/GymFeed/actions/runs/38530431988)
  passed both jobs and uploaded **3.0.7 (202610140811)**. Apple upload state
  became COMPLETE with no errors/warnings; build resource
  `d92e597a-ed67-428b-802a-b673bde9946f` was confirmed VALID, not expired, with
  export compliance answered (`usesNonExemptEncryption = false`). The matching
  pre-release version is 3.0.7 / IOS, and build beta details report
  **IN_BETA_TESTING** for the existing internal `testers` group
  (`557e5c84-ac50-4919-950e-3a3ed6801825`, access to all builds, auto-notify on).
  The external/public TestFlight group was not changed or submitted for beta
  review; use the existing internal tester account to install this build.
- Both testing deliveries are verified. No physical watch/phone installation
  was performed by these deployment checks, and production/main remain untouched.

The isolated feature-validation job uses macos-15 with Xcode 26.2 selected
explicitly after macos-26 runner-capacity delays. Store publishing workflows
are unchanged. A FirebaseFunctions Git download reset was an infrastructure
failure, not an application compile/test failure; the validation was retried.

The first macOS run compiled successfully, but actual Simulator installation
exposed a pre-existing notification-extension metadata defect: ImageNotification
used `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER` in its plist without inheriting
Generated.xcconfig. All three extension configurations now use dedicated xcconfig
files that inherit both their own Pods-ImageNotification configuration and the
generated Flutter settings. `scripts/validate_ios_extension_versions.py` checks the compiled
main/extension version fields and identity before installation. The full main
Simulator app is archived before the integration-test harness rebuilds Runner.

The Flutter integration-test installer automatically replaced the emulator's
previous app because its signature differed, removing its local app data. The
full new application was reinstalled after the smoke test. No live account or
backend data was modified.

`scripts/ios_health_capability.py` can inspect the existing GymFeed bundle ID or
enable HealthKit with an explicit `--enable` argument. On this date, inspection
with the previously downloaded local Apple API key did not find the GymFeed
bundle ID in that key's visible bundle-ID list. No Apple portal setting was
changed during that initial inspection. Follow-up deployment diagnostics found
that Apple's identifier filter returned no matches despite the exact existing
ID being present in the unfiltered list. The lookup now has a paginated,
exact-identifier fallback and rejects ambiguous IDs or unexpected pagination
hosts. Five read-only fixture tests cover this behavior. The capabilities
relationship also rejects a `limit` query parameter, so that parameter was
removed. HealthKit was then successfully enabled on the existing GymFeed App
ID `5GC64Y7SGV`, verified by a second API read. Existing Runner profiles became
invalid and the deployment's normal `fetch-signing-files --create` step must
create a compatible replacement; no existing profiles or certificates were
deleted by these diagnostics.

Before a store release:

- The Apple Developer App ID and refreshed signing profile must support
  HealthKit; the repository entitlement and Xcode capability are included.
- Google Play Health Connect declarations must match READ_STEPS,
  READ_ACTIVE_CALORIES_BURNED and READ_HEART_RATE and the described fitness use.
- The matching health-data privacy text is staged in the app and website policy.
- Verify Apple Watch → Apple Health and an Android watch companion → Health
  Connect on physical phones, including grants, revocation, empty days and
  returning from health settings. An emulator cannot prove watch synchronization.
- iOS compilation/signing and device validation require macOS. No iOS binary can
  be compiled on this Windows workstation. Do not equate Dart/unit tests with
  successful iOS build or physical-watch validation.

Local Windows Gradle workaround used only in the build process environment:
`JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=C:\android_setup\jdk\uds-temp -Djava.nio.channels.spi.SelectorProvider=sun.nio.ch.WindowsSelectorProvider`.
The installed JDK's default WEPoll selector failed with a Unix-domain loopback
error; selecting WindowsSelectorProvider allowed Gradle to build. No project
Gradle/JDK configuration was changed for this host-specific issue.

## Primary references used

- [Health Connect permissions UX](https://developer.android.com/health-and-fitness/health-connect/ui/permissions)
- [Health Connect aggregation](https://developer.android.com/health-and-fitness/health-connect/aggregate-data)
- [Health Connect setup](https://developer.android.com/health-and-fitness/health-connect/get-started)
- [Apple HealthKit authorization](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [health 12.2.1 package and native source](https://pub.dev/packages/health/versions/12.2.1)
