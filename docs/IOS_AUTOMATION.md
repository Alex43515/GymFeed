# GymFeed iOS and TestFlight Automation

GymFeed is a Flutter application. It must be built as Flutter on macOS/Xcode;
Expo Go is not used and no React Native conversion is required.

The workflow is stored at:

```text
.github/workflows/deploy-ios-testflight.yml
```

## Workflow behavior

- Every push to `main` that changes the Flutter or iOS application runs tests
  and creates an unsigned iOS Simulator build on GitHub's `macos-26` runner.
- A signed App Store IPA and TestFlight upload only run when the workflow is
  started manually with **publish_to_testflight** enabled.
- The signed job is protected by the GitHub environment
  `app-store-connect`.
- Both GymFeed targets receive App Store profiles:
  - `com.flutterflow.gymfeedofficial`
  - `com.flutterflow.gymfeedofficial.ImageNotification`
- The workflow uses an UTC timestamp as the App Store build number, uploads the
  IPA as a GitHub artifact, and then sends it to App Store Connect.

## Apple prerequisites

Before enabling TestFlight publishing:

1. Renew the Apple Developer Program membership.
2. Confirm that the existing GymFeed app record uses bundle ID
   `com.flutterflow.gymfeedofficial`.
3. Confirm that Apple Developer Certificates, Identifiers & Profiles contains
   both the main App ID and the notification extension App ID.
4. Enable the capabilities used by the app on the main App ID, including Push
   Notifications and Associated Domains. Enable Sign in with Apple before the
   Apple login button is released.
5. Complete any new Apple agreements shown in App Store Connect.

## Create the App Store Connect API key

In App Store Connect:

1. Open **Users and Access**.
2. Open **Integrations**, then **Team Keys**.
3. Create a key with **App Manager** access and access to Certificates,
   Identifiers & Profiles.
4. Record the Issuer ID and Key ID.
5. Download the `.p8` key. Apple only allows it to be downloaded once.

Do not commit or send the `.p8` file in chat.

## Create the distribution certificate private key

Create a dedicated 2048-bit RSA key on a trusted machine with OpenSSL:

```powershell
openssl genrsa -out "$env:TEMP\gymfeed-ios-distribution-key.pem" 2048
```

Keep this key private. The workflow uses it to find or create the Apple
Distribution certificate and must receive the same key on later runs.

## Add the GitHub environment and secrets

In GitHub open **Settings -> Environments -> New environment** and create:

```text
app-store-connect
```

Adding a required reviewer is recommended so a TestFlight upload cannot start
accidentally.

Add these environment secrets:

```text
APP_STORE_CONNECT_ISSUER_ID
APP_STORE_CONNECT_KEY_ID
APP_STORE_CONNECT_PRIVATE_KEY_BASE64
IOS_DISTRIBUTION_PRIVATE_KEY_BASE64
```

The first two values are the identifiers recorded in App Store Connect. Encode
the two private-key files locally before storing them:

```powershell
[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("C:\path\to\AuthKey_XXXXXXXXXX.p8")
) | Set-Clipboard

[Convert]::ToBase64String(
  [IO.File]::ReadAllBytes("$env:TEMP\gymfeed-ios-distribution-key.pem")
) | Set-Clipboard
```

Paste each clipboard value into its matching GitHub secret, then securely
remove local copies only after confirming that the secrets were saved and that
an encrypted backup exists.

## Run validation

After this workflow is committed and pushed to `main`, validation runs
automatically for relevant changes. It can also be run manually:

1. Open GitHub **Actions**.
2. Select **Validate GymFeed iOS and publish to TestFlight**.
3. Select **Run workflow**.
4. Leave **publish_to_testflight** disabled.

This mode does not need Apple credentials. Its `.app` artifact is for an iOS
Simulator and cannot be installed on a physical iPhone or submitted to Apple.

## Upload to TestFlight

After the membership, App IDs and GitHub secrets are ready:

1. Open the same workflow under GitHub Actions.
2. Select **Run workflow**.
3. Enable **publish_to_testflight**.
4. Approve the `app-store-connect` environment deployment if protection rules
   are enabled.
5. Wait for Apple to process the build, then assign it to an internal testing
   group in App Store Connect -> TestFlight.

The workflow uploads a build to App Store Connect; it does not automatically
submit a public App Store release for review.

## Important follow-up before public iOS release

- Replace the legacy `applinks:gymfeed.page.link` associated domain with or add
  `applinks:gymfeed.io`, then publish a valid
  `/.well-known/apple-app-site-association` file using the real Apple Team ID.
- Configure APNs/FCM iOS credentials and test one audible push on a physical
  iPhone.
- Complete Apple Sign in configuration in Apple and Supabase before showing
  the button as available.
- Configure the RevenueCat iOS app/product and verify the
  `premium_features` entitlement.
- Run Google OAuth, email verification, password reset, subscriptions, media
  upload/playback, deep links and background notifications on a physical
  iPhone.
- Review privacy manifests, App Privacy answers, screenshots, age rating,
  export compliance, account deletion and App Review notes.

## Troubleshooting

- If validation fails before signing, fix Flutter/Xcode/plugin compatibility
  first. Do not create Apple credentials to hide a compile failure.
- If signing-file creation fails, confirm the API key's role/access and that
  both App IDs exist under the renewed Apple team.
- If `flutter build ipa` cannot use the profile, inspect the profile mapping
  printed by `xcode-project use-profiles`, including the notification extension.
- If Apple rejects the build number, rerun later; every workflow run generates
  a newer UTC timestamp.
- Never weaken entitlements or remove the notification extension merely to make
  an archive compile.
