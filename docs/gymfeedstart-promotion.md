# GYMFEEDSTART

Same customer-facing code on both stores; 1,000 places per platform.
New subscribers only. First month discounted; subsequent months auto-renew at
the regular store price. Ends 15 January 2027 at 08:00 UTC (09:00 Belgrade).

| Store | US first / renewal | Serbia first / renewal | Redemption |
| --- | --- | --- | --- |
| Google Play | $22.50 / $25 | RSD 1,799.10 / 1,999 | Premium → Promo code → GYMFEEDSTART → Apply → Subscribe |
| Apple | $22.49 / $25 | EUR 15 / 16.99 | https://apps.apple.com/redeem?ctx=offercodes&id=6480524639&code=GYMFEEDSTART |

Apple regular prices take effect 29 November 2026. Start the shared email
campaign then. Google code entry requires GymFeed 3.0.18 or newer.

Google product `subscription_1_month`, base `subscription-1month`, offer
`gymfeedstart` is acquisition-only in US/RS and expires in Google Play itself.
The `rc-ignore-offer` tag prevents normal package checkout from automatically
selecting it. The app explicitly selects and validates its two pricing phases.

Android `public.android_promo` requires a confirmed signed-in account. Apply
previews eligibility without consuming a place. Subscribe atomically reserves
one of 1,000 places per account; retries reuse the reservation. Reservations
remain counted after cancellation/pending results to prevent uncertain purchases
from exceeding the cap. They do not grant Premium; RevenueCat verifies access.
Apple enforces its independent 1,000-redemption limit directly.

Operations: inspect `promo_private.campaigns` as an administrator for the Android
reservation count. It is intentionally inaccessible to app clients. Store
configuration can be read back using the Android workflow's `promo_action=inspect`;
`configure` changes only the two agreed prices and this offer. Do not email
service keys, store credentials, or database tokens to customers.
