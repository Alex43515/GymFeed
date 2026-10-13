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
- Only an account-scoped connection-preference boolean is saved locally. All
  health readings live in page memory; no Firestore, Supabase, AI, analytics,
  profile or cloud-cache integration. Disconnect clears that preference and
  page data, but users revoke OS permissions separately in their health app.
- There is no background worker. A connected page syncs on open, resume or
  manual refresh. Closing it ends the feature's automatic reads.
- Android uses FlutterFragmentActivity, provider availability checks, a native
  permissions-settings link and an independent scrollable privacy explanation
  for both Android 13 and Android 14+ health permission entry points.
- iOS includes HealthKit capability/entitlement, descriptive plist strings,
  native HealthKit availability checks and an Apple Health permissions link.
- Android minimum SDK changes from 24 to 26 because the compatible health plugin
  requires it. Health Connect itself requires Android 9/API 28 or later. Android
  8 can run GymFeed, but gets an unsupported health-connection message.

## Verification and release requirements

Automated coverage includes optional consent, denial, partial/revoked access,
account separation, reconnect, empty iOS data, failures/retry, disconnect,
concurrent refresh, calendar boundaries, system aggregation, duplicate samples,
invalid numeric readings, UI actions and unsupported platforms.

`integration_test/connected_health_device_test.dart` is a real native-plugin
smoke test for an Android 14+ emulator with Health Connect. It verifies provider
availability and renders the connect screen without login/backend writes or
requesting health permissions. It does not simulate a physical watch.

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
