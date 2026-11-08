-- Existing Android/iOS clients mark a server-created ticket as uploading before
-- transferring bytes to Bunny. The account-deletion hardening revoked that
-- UPDATE along with unsafe ownership/provider writes, breaking every upload.
-- Restore only the client handshake; keep the deletion ownership manifest and
-- webhook-only processing/ready states protected.
grant update (status) on public.media_assets to authenticated;

alter policy "own media update" on public.media_assets
  to authenticated
  using (
    (select auth.uid()) = owner_id
    and status in ('pending', 'uploading')
  )
  with check (
    (select auth.uid()) = owner_id
    and status = 'uploading'
  );

notify pgrst, 'reload schema';
