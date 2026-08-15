# Android internal deployment

GymFeed publishes signed Android App Bundles to Google Play's `internal`
testing track through `.github/workflows/deploy-android-internal.yml`.

The workflow runs for Android-relevant changes on `main`, including Flutter
code under `lib/`, and can also be started manually. It:

1. installs the pinned Flutter, Java, and Android API 36 toolchains;
2. runs the Flutter tests;
3. requests the next unused Play version code;
4. builds and verifies an upload-key-signed App Bundle;
5. stores the App Bundle as a GitHub artifact; and
6. commits it to the Play internal testing track.

## Required repository secrets

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`
- `ANDROID_UPLOAD_STORE_PASSWORD`

Secrets are installed in GitHub and are never stored in the repository.

## Safety gate

The repository variable `ANDROID_AUTO_DEPLOY_ENABLED` must equal `true` for
the job to run. Keep it disabled until the current Supabase app source has
been merged into `main`; this prevents an old GitHub snapshot from replacing a
newer internal build. Production promotion remains a manual Play Console step.
