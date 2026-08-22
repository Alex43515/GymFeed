-- Atomic account blocking. Besides hiding content, an Instagram-style block
-- removes follow relationships in both directions.
create or replace function public.block_user(p_blocked_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;
  if p_blocked_id is null or p_blocked_id = v_uid then
    raise exception 'Invalid account';
  end if;

  insert into public.user_blocks (blocker_id, blocked_id)
  values (v_uid, p_blocked_id)
  on conflict (blocker_id, blocked_id) do nothing;

  delete from public.follows
  where (follower_id = v_uid and followee_id = p_blocked_id)
     or (follower_id = p_blocked_id and followee_id = v_uid);
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

-- Direct workout queries (Events and FitClips) must respect blocks in either
-- direction just like the Home/Reels RPCs do. A SECURITY DEFINER predicate can
-- inspect both rows while the user_blocks table itself remains owner-private.
create or replace function public.can_view_account(p_account_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select auth.uid() is not null
     and not exists (
       select 1
       from public.user_blocks b
       where (b.blocker_id = auth.uid() and b.blocked_id = p_account_id)
          or (b.blocker_id = p_account_id and b.blocked_id = auth.uid())
     );
$$;

revoke all on function public.can_view_account(uuid) from public;
grant execute on function public.can_view_account(uuid) to authenticated;

drop policy if exists "trainings readable" on public.user_trainings;
create policy "trainings readable without blocked accounts"
on public.user_trainings
for select
to authenticated
using (public.can_view_account(user_id));
