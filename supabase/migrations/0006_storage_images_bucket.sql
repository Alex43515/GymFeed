-- 0006_storage_images_bucket.sql
-- Provisions the Supabase Storage bucket the app uploads photos to.
--
-- The client (lib/backend/firebase_storage/storage.dart and
-- lib/backend/supabase/repositories/media_repository.dart) writes profile
-- photos and post images via `supabase.storage.from('images')` using object
-- keys shaped `<uid>/<uuid>.<ext>`. Without this bucket and its storage.objects
-- RLS policies every upload was rejected (uploadData caught the error and
-- returned null -> "Upload failed"). Reads are public because the app serves
-- images through getPublicUrl().

-- 1. The bucket itself (public read, ~15 MB per-object cap).
insert into storage.buckets (id, name, public, file_size_limit)
values ('images', 'images', true, 15728640)
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit;

-- 2. RLS on storage.objects for this bucket.
--    Keys begin with the caller's uid folder, so a user may only write under
--    their own prefix; anyone may read (bucket is public).

drop policy if exists "images public read" on storage.objects;
create policy "images public read"
  on storage.objects for select
  using (bucket_id = 'images');

drop policy if exists "images insert own" on storage.objects;
create policy "images insert own"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "images update own" on storage.objects;
create policy "images update own"
  on storage.objects for update to authenticated
  using (
    bucket_id = 'images'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "images delete own" on storage.objects;
create policy "images delete own"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
