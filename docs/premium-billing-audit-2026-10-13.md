# Premium billing audit — 2026-10-13

## Result and scope

The mobile paywall uses RevenueCat's current monthly package, with the
`premium_features` entitlement controlling premium Coach access. The initial
3.0.6 test build contained a cached-access bug. Fixes were prepared in this
audit and subsequently uploaded to both test channels, as recorded below.
No real purchase, refund, store configuration change, or production release
was performed during this audit or the subsequent test deployment.

This is a code/SDK contract test plus read-only checks against live services.
It is **not** a completed StoreKit/Google Play checkout test. Native store
availability, actual price/billing-period metadata, product-to-entitlement
assignment, receipt validation, renewals and webhook delivery must still be
verified with a genuine sandbox transaction on a device.

## Live observations

RevenueCat's public SDK API returned the current offering `subscription`:

| Platform | Monthly package | Product | Android base plan |
| --- | --- | --- | --- |
| iOS | `$rc_monthly` | `premium_2999_1m` | — |
| Android | `$rc_monthly` | `subscription_1_month` | `subscription-1month` |

The offerings response establishes the configured package mapping; it does
not include authoritative native store billing-period metadata. The SDK keys
in `main.dart` are platform-specific public keys. No private credentials are
included in this report.

At 2026-10-13 13:43:33 UTC, the RevenueCat subscriber record for the Supabase
UID belonging to `alexZ` had zero subscriptions and zero entitlements. The
designated QA UID also had no subscription receipts in the checked record.
These observations apply to these specific subscriber IDs, not every customer
or possible anonymous/aliased purchase in the project.

The QA account has an explicit unlimited-premium override in
`ai_usage_gate.dart`. It cannot demonstrate paid access expiring normally.

The deployed Supabase `revenuecat-webhook` function records marketing events;
it does not grant/revoke premium. Access comes from RevenueCat CustomerInfo.
The inspected marketing event history contained three RevenueCat TEST events,
and no actual purchase, renewal or expiration event. This does not establish
that delivery is broken. An unauthenticated POST probe returned HTTP 401
`{"error":"unauthorized"}` without creating a subscription event.

## Duration: one month is not a fixed 30 days

The current offering and paywall describe a monthly auto-renewing subscription.
A calendar month can be 28, 29, 30 or 31 days. For example, October 13 to
November 13 is 31 calendar days. The app must respect the store's exact receipt
expiry and RevenueCat entitlement status instead of adding 30 days locally.
Apple describes calendar-date renewal and end-of-month handling in its
[subscription reference](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/auto-renewable-subscription-information).
Google documents billing-date handling in its
[subscription lifecycle](https://developer.android.com/google/play/billing/lifecycle/subscriptions).

Cancellation disables future renewal but retains the remaining paid access.
Successful renewal extends access; a refund/revocation can end access early.
Store billing grace periods can retain access beyond the normal paid expiry.
Use RevenueCat's refreshed `isActive` status for these decisions; see
[CustomerInfo](https://www.revenuecat.com/docs/customers/customer-info) and
[grace periods](https://www.revenuecat.com/docs/subscription-guidance/how-grace-periods-work).

## Fixes prepared

- Removed the premium gate's cached-active early return. Each access consults
  the SDK; an elapsed cached expiry invalidates the SDK cache before refresh.
- Bound the restored Supabase session to RevenueCat before app startup and
  before purchase/restore/access checks.
- Cleared premium immediately on account changes, serialized native identity
  changes, shared concurrent login requests for the same account, and discarded
  delayed customer/purchase/restore responses from an older identity.
- Required an active `premium_features` entitlement before showing purchase
  success. Pending approval and user cancellation have separate outcomes.
- Prevented simultaneous checkout calls and false restore success after an
  unsuccessful restore operation.

Existing product pricing, renewal terms and QA exceptions remain as configured.
No fixed 30-day cutoff was introduced.

## Automated verification

Flutter 3.27.4 / Dart 3.6.2 / purchases_flutter 10.9.1.

`test/revenue_cat_billing_test.dart` contains 27 mocked native-channel tests:
expired cache, refreshed access, the actual AI premium gate, calendar periods
28/29/30/31 days, cancellation, renewal, billing grace and its end, revocation,
network failure, logout, serialized/coalesced account switches, successful
purchase, missing entitlement, cancellation/pending/native errors, restore,
failed identity binding, delayed old-account responses, duplicate checkout,
and iOS/Android public-key and monthly-package selection.

The billing tests do not contact or charge an app store. Calendar/receipt
fixtures validate the app's handling of store-supplied dates, not Apple/Google's
production contract. Full Flutter suite: 246 passed, 4 skipped (existing live
tests without supplied credentials). Scoped analysis: no issues. `git diff
--check`: clean.

## Remaining device verification

1. Install a new test build containing these fixes and sign into an ordinary
   GymFeed account, without the QA override.
2. On Android, use a configured Google Play **license tester** and confirm
   checkout shows a test payment method. Internal-track membership alone can
   still result in a real charge; see
   [Google Play sandbox guidance](https://www.revenuecat.com/docs/test-and-launch/sandbox/google-play-store).
3. On iOS, use TestFlight/sandbox checkout. TestFlight renewals are accelerated,
   so a test subscription need not remain active for a production month; see
   [Apple TestFlight subscription testing](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testing-subscriptions-and-in-app-purchases-in-testflight).
4. Capture the sandbox receipt's purchase time, exact expiry, product ID,
   `premium_features` status and Supabase user mapping. Verify purchase,
   relaunch, restore, another device/account, renewal, cancellation and lapse.
5. Verify signed purchase/renewal/expiration events reach the existing webhook
   and are deduplicated. Their absence from the inspected history leaves this
   delivery path unconfirmed.

The user's purchased/tested account and platform were requested during this
audit to check actual receipt dates. No such account was supplied before this
report was prepared.

## Subsequent test deployment — 2026-10-13

At the user's request, source commit
`2f9666950ac9a33c55ea0dee87719a83f83d4b61` was deployed from `release/3.0.6`:

| Platform | Version | Build | Confirmed destination |
| --- | --- | --- | --- |
| Android | 3.0.6 | 222 | Google Play `internal` |
| iOS | 3.0.6 | 202610131418 | Apple TestFlight upload |

The [Android run](https://github.com/Alex43515/GymFeed/actions/runs/38408517750)
completed successfully and reported `track: internal, versionCode: 222` after
the Play edit was committed. Artifact ID: `11820412845`.

The [iOS run](https://github.com/Alex43515/GymFeed/actions/runs/38408516889)
completed both validation and signed upload successfully, with `UPLOAD
SUCCEEDED with no errors` at 14:28:28 UTC. IPA artifact ID: `11821489666`.
Apple processing and actual tester availability were not independently
confirmed. No main merge or production store deployment was performed.

This deployment does not substitute for the remaining native sandbox purchase
and receipt/webhook verification described above.
