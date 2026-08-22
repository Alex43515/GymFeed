-- 0009_videos_bucket.sql
-- A public `videos` bucket so seeded/test video posts can be served directly to
-- the player (the app's bunnyCDNVideoPath() passes non-Firebase URLs through
-- unchanged, so a Supabase public URL plays as-is). Real production uploads
-- still go to Bunny Stream; this is for direct-hosted / seed content.

insert into storage.buckets (id, name, public, file_size_limit)
values ('videos', 'videos', true, 209715200)  -- 200 MB per object
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit;

drop policy if exists "videos public read" on storage.objects;
create policy "videos public read"
  on storage.objects for select
  using (bucket_id = 'videos');

drop policy if exists "videos insert own" on storage.objects;
create policy "videos insert own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "videos update own" on storage.objects;
create policy "videos update own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "videos delete own" on storage.objects;
create policy "videos delete own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'videos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
