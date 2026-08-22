-- Owners can disable likes/comments from the post options sheet. Enforce those
-- settings in RLS as well as the UI so stale or older clients cannot bypass
-- them after the post has been updated.

drop policy if exists "like as self" on public.post_likes;
create policy "like as self"
on public.post_likes
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
      from public.posts p
     where p.id = post_id
       and not p.deleted
       and p.allow_likes
  )
);

drop policy if exists "comment as self" on public.comments;
create policy "comment as self"
on public.comments
for insert
with check (
  auth.uid() = user_id
  and exists (
    select 1
      from public.posts p
     where p.id = post_id
       and not p.deleted
       and p.allow_comments
  )
);
