-- Complete account blocking and content reporting for the Supabase app.

alter table public.reports
  add column if not exists reported_user_id uuid references public.profiles(id) on delete set null,
  add column if not exists content_type text not null default 'post',
  add column if not exists reason text not null default '',
  add column if not exists status text not null default 'open',
  add column if not exists metadata jsonb not null default '{}'::jsonb,
  add column if not exists notified_at timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'reports_content_type_check'
  ) then
    alter table public.reports add constraint reports_content_type_check
      check (content_type in ('post', 'food_post', 'workout', 'account'));
  end if;
  if not exists (
    select 1 from pg_constraint where conname = 'reports_status_check'
  ) then
    alter table public.reports add constraint reports_status_check
      check (status in ('open', 'reviewing', 'resolved', 'dismissed'));
  end if;
end $$;

create index if not exists reports_moderation_idx
  on public.reports (status, created_at desc);
create index if not exists reports_reported_user_idx
  on public.reports (reported_user_id, created_at desc);

-- The user_blocks table deliberately exposes only rows owned by the current
-- user. This definer function can safely tell the UI which side of the block it
-- is on without revealing another user's private block list.
create or replace function public.account_block_relationship(p_account_id uuid)
returns text
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select case
    when auth.uid() is null or p_account_id is null then 'none'
    when exists (
      select 1 from public.user_blocks
      where blocker_id = auth.uid() and blocked_id = p_account_id
    ) then 'blocked_by_me'
    when exists (
      select 1 from public.user_blocks
      where blocker_id = p_account_id and blocked_id = auth.uid()
    ) then 'blocked_me'
    else 'none'
  end;
$$;

revoke all on function public.account_block_relationship(uuid) from public;
grant execute on function public.account_block_relationship(uuid) to authenticated;

create or replace function public.mark_report_notified(p_report_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  update public.reports set notified_at = coalesce(notified_at, now())
  where id = p_report_id and reporter_id = auth.uid();
$$;

revoke all on function public.mark_report_notified(uuid) from public;
grant execute on function public.mark_report_notified(uuid) to authenticated;

create or replace function public.can_view_account(p_account_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select auth.uid() is not null
     and p_account_id is not null
     and not exists (
       select 1 from public.user_blocks b
       where (b.blocker_id = auth.uid() and b.blocked_id = p_account_id)
          or (b.blocker_id = p_account_id and b.blocked_id = auth.uid())
     );
$$;

revoke all on function public.can_view_account(uuid) from public;
grant execute on function public.can_view_account(uuid) to authenticated;

-- Instagram-style block: sever both follow directions and hide any existing
-- one-to-one conversation without deleting its messages.
create or replace function public.block_user(p_blocked_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if p_blocked_id is null or p_blocked_id = v_uid then
    raise exception 'Invalid account';
  end if;

  insert into public.user_blocks (blocker_id, blocked_id)
  values (v_uid, p_blocked_id)
  on conflict (blocker_id, blocked_id) do nothing;

  delete from public.follows
  where (follower_id = v_uid and followee_id = p_blocked_id)
     or (follower_id = p_blocked_id and followee_id = v_uid);

  delete from public.chat_members cm
  where cm.user_id in (v_uid, p_blocked_id)
    and cm.chat_id in (
      select mine.chat_id
      from public.chat_members mine
      join public.chat_members theirs on theirs.chat_id = mine.chat_id
      where mine.user_id = v_uid and theirs.user_id = p_blocked_id
        and (select count(*) from public.chat_members all_members
             where all_members.chat_id = mine.chat_id) = 2
    );
end;
$$;

create or replace function public.unblock_user(p_blocked_id uuid)
returns void
language sql
security definer
set search_path = public, pg_temp
as $$
  delete from public.user_blocks
  where blocker_id = auth.uid() and blocked_id = p_blocked_id;
$$;

revoke all on function public.block_user(uuid) from public;
revoke all on function public.unblock_user(uuid) from public;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;

-- Direct table reads and writes must match the already block-aware feed RPCs.
drop policy if exists "posts readable by authenticated" on public.posts;
drop policy if exists "posts readable without blocked accounts" on public.posts;
create policy "posts readable without blocked accounts"
  on public.posts for select to authenticated
  using (public.can_view_account(user_id));

drop policy if exists "likes readable" on public.post_likes;
create policy "likes readable without blocked accounts"
  on public.post_likes for select to authenticated
  using (public.can_view_account(user_id)
    and exists (select 1 from public.posts p where p.id = post_id));
drop policy if exists "like as self" on public.post_likes;
create policy "like visible post as self"
  on public.post_likes for insert to authenticated
  with check (auth.uid() = user_id
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and not p.deleted
        and p.allow_likes
        and public.can_view_account(p.user_id)
    ));

drop policy if exists "comments readable" on public.comments;
create policy "comments readable without blocked accounts"
  on public.comments for select to authenticated
  using (public.can_view_account(user_id)
    and exists (select 1 from public.posts p where p.id = post_id));
drop policy if exists "comment as self" on public.comments;
create policy "comment on visible post as self"
  on public.comments for insert to authenticated
  with check (auth.uid() = user_id
    and exists (
      select 1 from public.posts p
      where p.id = post_id
        and not p.deleted
        and p.allow_comments
        and public.can_view_account(p.user_id)
    ));

drop policy if exists "follows readable" on public.follows;
create policy "follows readable without blocked accounts"
  on public.follows for select to authenticated
  using (public.can_view_account(follower_id)
    and public.can_view_account(followee_id));
drop policy if exists "follow as self" on public.follows;
create policy "follow visible account as self"
  on public.follows for insert to authenticated
  with check (auth.uid() = follower_id
    and public.can_view_account(followee_id));

drop policy if exists "own notifications read" on public.notifications;
create policy "own visible notifications read"
  on public.notifications for select to authenticated
  using (auth.uid() = recipient_id
    and (actor_id is null or public.can_view_account(actor_id)));
drop policy if exists "notify as actor" on public.notifications;
create policy "notify visible recipient as actor"
  on public.notifications for insert to authenticated
  with check (auth.uid() = actor_id
    and public.can_view_account(recipient_id));

drop policy if exists "join or add to chat" on public.chat_members;
create policy "join or add visible member to chat"
  on public.chat_members for insert to authenticated
  with check ((user_id = auth.uid() or public.is_chat_member(chat_id))
    and public.can_view_account(user_id));
drop policy if exists "send message as self to own chat" on public.chat_messages;
create policy "send message to visible chat members"
  on public.chat_messages for insert to authenticated
  with check (auth.uid() = user_id and public.is_chat_member(chat_id)
    and not exists (
      select 1 from public.chat_members cm
      where cm.chat_id = chat_messages.chat_id
        and not public.can_view_account(cm.user_id)
    ));

drop policy if exists "file report as self" on public.reports;
create policy "file report as self"
  on public.reports for insert to authenticated
  with check (auth.uid() = reporter_id and reporter_id <> reported_user_id);
create policy "read own filed reports"
  on public.reports for select to authenticated
  using (auth.uid() = reporter_id);
