-- Supabase-native Story receipts, block safety, and live tray updates.

create index if not exists story_views_viewer_idx
  on public.story_views (viewer_id, viewed_at desc);

create or replace function public.can_view_story_author(p_author_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select auth.uid() is not null
     and not exists (
       select 1
         from public.user_blocks block
        where (block.blocker_id = auth.uid() and block.blocked_id = p_author_id)
           or (block.blocker_id = p_author_id and block.blocked_id = auth.uid())
     );
$$;

revoke all on function public.can_view_story_author(uuid) from public;
grant execute on function public.can_view_story_author(uuid) to authenticated;

drop policy if exists "stories readable" on public.stories;
create policy "stories readable"
  on public.stories for select
  using (
    auth.role() = 'authenticated'
    and public.can_view_story_author(user_id)
  );

drop policy if exists "story views readable by story owner" on public.story_views;
drop policy if exists "story views readable by owner or viewer" on public.story_views;
create policy "story views readable by owner or viewer"
  on public.story_views for select
  using (
    viewer_id = auth.uid()
    or exists (
      select 1
        from public.stories story
       where story.id = story_id
         and story.user_id = auth.uid()
    )
  );

drop policy if exists "update own story view" on public.story_views;
create policy "update own story view"
  on public.story_views for update
  using (viewer_id = auth.uid())
  with check (viewer_id = auth.uid());

do $$
begin
  alter publication supabase_realtime add table public.stories;
exception
  when duplicate_object then null;
end;
$$;

do $$
begin
  alter publication supabase_realtime add table public.story_views;
exception
  when duplicate_object then null;
end;
$$;
