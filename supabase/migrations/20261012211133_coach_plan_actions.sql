-- Exact reviewed payloads are shared by chat, Train and Meal Diary.
create table public.ai_coach_plan_actions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'implemented', 'skipped', 'superseded')),
  payload jsonb not null check (
    jsonb_typeof(payload) = 'object'
    and payload ? 'workouts' and payload ? 'meals'
    and jsonb_typeof(payload->'workouts') = 'array'
    and jsonb_typeof(payload->'meals') = 'array'
    and jsonb_array_length(payload->'workouts') <= 28
    and jsonb_array_length(payload->'meals') <= 168
    and jsonb_array_length(payload->'workouts') + jsonb_array_length(payload->'meals') > 0
  ),
  start_date date not null,
  end_date date not null check (end_date >= start_date and end_date <= start_date + 27),
  created_at timestamptz not null default now()
);

create unique index ai_coach_one_pending_plan_per_user
  on public.ai_coach_plan_actions (user_id) where status = 'pending';
create index ai_coach_plan_user_status_dates
  on public.ai_coach_plan_actions (user_id, status, start_date, end_date);
create index ai_coach_plan_user_created
  on public.ai_coach_plan_actions (user_id, created_at desc);

alter table public.ai_coach_plan_actions enable row level security;
create policy "read own coach plans" on public.ai_coach_plan_actions
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "create own pending coach plans" on public.ai_coach_plan_actions
  for insert to authenticated with check (
    (select auth.uid()) = user_id and status = 'pending'
  );
create policy "update own coach plan status" on public.ai_coach_plan_actions
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.ai_coach_plan_actions from anon, authenticated;
grant select, insert on public.ai_coach_plan_actions to authenticated;
grant update (status) on public.ai_coach_plan_actions to authenticated;
grant all on public.ai_coach_plan_actions to service_role;

-- Serialize proposal replacement for this user. Retrying an identical id never
-- replaces a later proposal or changes an implemented payload.
create function public.save_coach_plan_action(
  p_id uuid, p_payload jsonb, p_start_date date, p_end_date date
) returns jsonb language plpgsql security invoker set search_path = '' as $$
declare
  owner_id uuid := auth.uid();
  result public.ai_coach_plan_actions;
begin
  if owner_id is null then raise exception 'Authentication required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(owner_id::text, 0));
  select * into result from public.ai_coach_plan_actions
    where id = p_id and user_id = owner_id;
  if found then return to_jsonb(result); end if;
  update public.ai_coach_plan_actions set status = 'superseded'
    where user_id = owner_id and status = 'pending';
  insert into public.ai_coach_plan_actions
    (id, user_id, payload, start_date, end_date)
    values (p_id, owner_id, p_payload, p_start_date, p_end_date)
    returning * into result;
  return to_jsonb(result);
end;
$$;

-- Confirmation is atomic. Implemented/skipped/superseded plans cannot be
-- reopened by another tap, a stale device or a repeated chat confirmation.
create function public.set_coach_plan_action_status(p_id uuid, p_status text)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare result public.ai_coach_plan_actions;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_status not in ('implemented', 'skipped') then
    raise exception 'Invalid plan transition';
  end if;
  update public.ai_coach_plan_actions set status = p_status
    where id = p_id and user_id = auth.uid() and status = 'pending'
    returning * into result;
  if not found then
    select * into result from public.ai_coach_plan_actions
      where id = p_id and user_id = auth.uid();
  end if;
  if result.id is null then raise exception 'Plan not found'; end if;
  return to_jsonb(result);
end;
$$;

revoke execute on function public.save_coach_plan_action(uuid,jsonb,date,date)
  from public, anon;
revoke execute on function public.set_coach_plan_action_status(uuid,text)
  from public, anon;
grant execute on function public.save_coach_plan_action(uuid,jsonb,date,date)
  to authenticated;
grant execute on function public.set_coach_plan_action_status(uuid,text)
  to authenticated;
