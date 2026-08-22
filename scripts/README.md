# GymFeed content seeder

Creates **5 fake profiles** and, per profile, uploads **10 videos + 5 images**
to Supabase Storage and inserts matching posts — so the feed, reels, and profile
grids are full of real content to test look & load speed.

Videos → `videos` bucket, images → `images` bucket (both auto-created).
Posts store the public URLs; the app's `bunnyCDNVideoPath`/`bunnyCDNImagePath`
pass these straight through, so they play/display as-is (no Bunny needed).

## One-time setup

1. **Create `scripts/.env`** (this folder) with your keys — do NOT commit it:

   ```
   SUPABASE_URL=https://bzinwojowkxavfzilvat.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=<your service_role key from Settings → API>
   VIDEO_DIR=C:/Users/My SM PC/OneDrive/moji projekti/instagram_downloads
   IMAGE_DIR=C:/Users/My SM PC/OneDrive/GymFeed all/gymfeed content/2024 GYM FEED/2024 GYM FEED/MOODBOARD
   ```

2. Dependencies are already installed (`npm install` was run). If not: `npm install`.

## Run

```bash
npm run seed
```

That's it. It prints progress and finishes with the login for each profile:
`<username>@gymfeed.test` / `GymFeed123!` (e.g. `sophygreen@gymfeed.test`).

Re-running is safe — existing users are reused, more posts are appended.

## Also required for the app to display this content

Apply these migrations in the Supabase **SQL Editor** (the seeder auto-creates the
buckets, but these add the feed/reels ranking functions the app reads from):

- `supabase/migrations/0007_feed_relevance.sql`
- `supabase/migrations/0008_reels_page.sql`

## Security

`scripts/.env` is git-ignored. **Rotate any key you pasted into chat** (the DB
password and the service_role key) after seeding: Supabase → Settings → API →
reset `service_role`, and Settings → Database → reset password.

## Tuning

Env overrides: `VIDEOS_PER_USER`, `IMAGES_PER_USER`, `SEED_PASSWORD`.
Note: 50 videos can be a few hundred MB of Storage — mind your project quota.
