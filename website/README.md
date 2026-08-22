# GymFeed website deployment

This package is designed for the Namecheap Stellar account attached to
`gymfeed.io`.

## Upload

1. Open Namecheap cPanel and then **File Manager**.
2. Open `public_html`.
3. Remove the Namecheap placeholder `index.html` only after downloading a
   backup if desired.
4. Upload the *contents* of this package's `public_html` folder, including the
   hidden `.htaccess` and `.well-known` entries.
5. Confirm these URLs over HTTPS:
   - `https://gymfeed.io/`
   - `https://gymfeed.io/privacy/`
   - `https://gymfeed.io/terms/`
   - `https://gymfeed.io/support/`
   - `https://gymfeed.io/.well-known/assetlinks.json`

The `post.php` page securely reuses the existing public Supabase share-post
function. No Supabase service key or other secret belongs in this hosting
account.

The `www.gymfeed.io` TLS certificate currently needs to be issued by Namecheap
SSL. The canonical Android App Links host is the non-www `gymfeed.io`, so that
does not block initial Android verification.
