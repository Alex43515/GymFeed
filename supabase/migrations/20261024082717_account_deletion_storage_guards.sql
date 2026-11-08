-- Old access tokens must not create new files after the profile is deleted.
create policy "active account required for storage insert"
on storage.objects as restrictive for insert to authenticated
with check (exists (select 1 from public.profiles where id = (select auth.uid())));

create policy "active account required for storage update"
on storage.objects as restrictive for update to authenticated
using (exists (select 1 from public.profiles where id = (select auth.uid())))
with check (exists (select 1 from public.profiles where id = (select auth.uid())));

-- Bunny deletion trusts this ownership manifest. Only the upload/webhook
-- services may create, reassign, or remove its provider identifiers.
revoke insert, update, delete, truncate, references, trigger
on public.media_assets from anon, authenticated;
