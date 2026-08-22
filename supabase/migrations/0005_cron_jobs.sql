-- 0005_cron_jobs.sql
-- Enable pg_cron + pg_net and register the two media lifecycle jobs:
--   1. gymfeed-media-gc        — hourly: mark stuck pending/uploading rows failed
--   2. gymfeed-media-reconcile — every 15 min: mark long-stuck processing rows failed

-- ─── Extensions ───────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- pg_cron runs as the `postgres` role; it needs USAGE on the cron schema.
GRANT USAGE ON SCHEMA cron TO postgres;

-- ─── 1. GC: pending / uploading rows stuck for > 24 h ────────────────────────
-- These rows represent uploads that were never started or abandoned before
-- Bunny received any bytes. The TUS ticket expires after 1 h; after 24 h the
-- row is definitively orphaned and can be marked failed so the UI shows retry.
--
-- Full GC (deleting the Bunny video object) requires a scheduled Edge Function
-- with access to BUNNY_STREAM_API_KEY — add that in a later migration once
-- pg_net Vault integration is wired up.
SELECT cron.schedule(
  'gymfeed-media-gc',
  '0 * * * *',           -- every hour at :00
  $$
    UPDATE public.media_assets
       SET status     = 'failed',
           updated_at = NOW()
     WHERE status IN ('pending', 'uploading')
       AND created_at < NOW() - INTERVAL '24 hours';
  $$
);

-- ─── 2. Reconciler: processing rows stuck for > 30 min ───────────────────────
-- A normal Bunny encode takes < 5 min for short gym clips.  If a row has been
-- in `processing` for 30+ minutes the webhook was likely missed or dropped.
-- Mark it failed so the author sees a retry prompt.  A full reconciler that
-- actually checks Bunny's encode status would run as an Edge Function (pg_net
-- → supabase functions/v1/media-reconcile) — placeholder for a future sprint.
SELECT cron.schedule(
  'gymfeed-media-reconcile',
  '*/15 * * * *',         -- every 15 minutes
  $$
    UPDATE public.media_assets
       SET status     = 'failed',
           updated_at = NOW()
     WHERE status     = 'processing'
       AND updated_at < NOW() - INTERVAL '30 minutes';
  $$
);
