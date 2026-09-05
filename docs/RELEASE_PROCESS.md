# GymFeed release process

GymFeed uses one versioned release branch for Android and iOS.

## Testing

1. Create or work on `release/X.Y.Z`.
2. Keep the `version:` in `pubspec.yaml` equal to `X.Y.Z`.
3. Push or merge app changes into that release branch.
4. GitHub Actions automatically publishes:
   - Android to Google Play Internal testing.
   - iOS to TestFlight. The internal `testers` group has access to all builds.

For the current release, use `release/2.2.3` and `version: 2.2.3+206`.

## Production

When the same release has passed testing, open a pull request from
`release/X.Y.Z` into `main` and merge it. App-related changes on `main`
automatically publish:

- Android to the Google Play Production track.
- iOS to App Store Connect and then submit the version to App Review. Apple
  review cannot be skipped. The version is configured to release automatically
  after Apple approves it.
- Web changes to the production website at `gymfeed.io`.

Do not push unfinished application changes directly to `main`; `main` is the
production release branch.

## Manual runs

Both mobile workflows support a manual destination selector in GitHub Actions.
Use it only for an intentional rerun. Normal releases should follow the branch
rules above.
