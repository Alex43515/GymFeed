-- Community training plans, phase 2: every exercise in a plan needs an
-- explanation video, and plans are reviewed in the app by GymFeed admins.
--
-- One video per exercise per plan: "Squat" on day 1 and day 8 share a video.
-- Admins are listed in app_admins; add one with
--   insert into public.app_admins (user_id) values ('<profile id>');

create table if not exists public.app_admins (
  user_id    uuid primary key references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now()
);
-- No policies: the list is only readable through is_app_admin().
alter table public.app_admins enable row level security;

create or replace function public.is_app_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select auth.uid() is not null
     and exists (select 1 from public.app_admins where user_id = auth.uid());
$$;

create table if not exists public.training_plan_exercise_videos (
  plan_id        uuid not null references public.training_plans (id) on delete cascade,
  exercise_key   text not null check (char_length(exercise_key) between 1 and 120),
  exercise_name  text not null check (char_length(exercise_name) between 1 and 120),
  video_asset_id uuid not null references public.media_assets (id) on delete restrict,
  created_at     timestamptz not null default now(),
  primary key (plan_id, exercise_key)
);

create index if not exists training_plan_exercise_videos_asset_idx
  on public.training_plan_exercise_videos (video_asset_id);

alter table public.training_plan_exercise_videos enable row level security;

-- Admins can read plans waiting for review, including their days and videos.
drop policy if exists "read published or own plans" on public.training_plans;
create policy "read published or own plans"
  on public.training_plans for select
  to authenticated
  using (status = 'published' or seller_id = auth.uid() or public.is_app_admin());

drop policy if exists "read days of visible plans" on public.training_plan_days;
create policy "read days of visible plans"
  on public.training_plan_days for select
  to authenticated
  using (exists (
    select 1 from public.training_plans p
    where p.id = plan_id
      and (p.status = 'published' or p.seller_id = auth.uid() or public.is_app_admin())
  ));

drop policy if exists "read videos of visible plans" on public.training_plan_exercise_videos;
create policy "read videos of visible plans"
  on public.training_plan_exercise_videos for select
  to authenticated
  using (exists (
    select 1 from public.training_plans p
    where p.id = plan_id
      and (p.status = 'published' or p.seller_id = auth.uid() or public.is_app_admin())
  ));

-- The phase-1 signature is replaced by one with p_videos. The default keeps
-- phase-1 app builds (three named arguments) working.
drop function if exists public.save_training_plan(uuid, jsonb, jsonb);

-- p_videos: [{"exercise_name", "video_asset_id"}], one per distinct exercise.
create or replace function public.save_training_plan(
  p_plan_id uuid,
  p_fields jsonb,
  p_days jsonb,
  p_videos jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_id uuid := p_plan_id;
  v_status text;
  v_count int := coalesce(jsonb_array_length(p_days), 0);
  v_foreign int;
begin
  if v_uid is null then raise exception 'Sign in to create plans'; end if;
  if jsonb_typeof(p_days) is distinct from 'array' or v_count < 1 or v_count > 31 then
    raise exception 'A plan has between 1 and 31 days';
  end if;
  if jsonb_typeof(coalesce(p_videos, '[]'::jsonb)) <> 'array' then
    raise exception 'Videos must be a list';
  end if;

  select count(*) into v_foreign
  from jsonb_array_elements(coalesce(p_videos, '[]'::jsonb)) as item(value)
  left join public.media_assets a on a.id = nullif(item.value ->> 'video_asset_id', '')::uuid
  where a.id is null or a.owner_id <> v_uid or a.kind <> 'video';
  if v_foreign > 0 then raise exception 'Exercise videos must be your own uploads'; end if;

  perform set_config('gymfeed.plan_server_write', 'on', true);
  if v_id is null then
    insert into public.training_plans (seller_id, title, description, goal, level, equipment, day_count)
    values (
      v_uid,
      trim(p_fields ->> 'title'),
      coalesce(trim(p_fields ->> 'description'), ''),
      coalesce(p_fields ->> 'goal', 'general'),
      coalesce(p_fields ->> 'level', 'intermediate'),
      coalesce(p_fields ->> 'equipment', 'gym'),
      v_count
    )
    returning id into v_id;
  else
    select status into v_status from public.training_plans
    where id = v_id and seller_id = v_uid
    for update;
    if v_status is null then raise exception 'Plan not found'; end if;
    if v_status not in ('draft', 'rejected') then
      raise exception 'Unpublish the plan before editing it';
    end if;
    update public.training_plans set
      title = trim(p_fields ->> 'title'),
      description = coalesce(trim(p_fields ->> 'description'), ''),
      goal = coalesce(p_fields ->> 'goal', goal),
      level = coalesce(p_fields ->> 'level', level),
      equipment = coalesce(p_fields ->> 'equipment', equipment),
      day_count = v_count,
      status = 'draft'
    where id = v_id;
    delete from public.training_plan_days where plan_id = v_id;
    delete from public.training_plan_exercise_videos where plan_id = v_id;
  end if;

  insert into public.training_plan_days (plan_id, day, kind, title, notes, exercises)
  select
    v_id,
    item.ordinality::int,
    case when item.value ->> 'kind' = 'rest' then 'rest' else 'workout' end,
    coalesce(trim(item.value ->> 'title'), ''),
    coalesce(trim(item.value ->> 'notes'), ''),
    case when item.value ->> 'kind' = 'rest' then '[]'::jsonb
         else coalesce(item.value -> 'exercises', '[]'::jsonb) end
  from jsonb_array_elements(p_days) with ordinality as item(value, ordinality);

  insert into public.training_plan_exercise_videos (plan_id, exercise_key, exercise_name, video_asset_id)
  select distinct on (lower(trim(item.value ->> 'exercise_name')))
    v_id,
    lower(trim(item.value ->> 'exercise_name')),
    trim(item.value ->> 'exercise_name'),
    (item.value ->> 'video_asset_id')::uuid
  from jsonb_array_elements(coalesce(p_videos, '[]'::jsonb)) as item(value)
  where trim(coalesce(item.value ->> 'exercise_name', '')) <> '';

  return v_id;
end;
$$;

-- Same checks as phase 1, plus: every exercise has an uploaded video.
create or replace function public.submit_training_plan(p_plan_id uuid)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_plan public.training_plans;
  v_days int;
  v_workouts int;
  v_empty int;
  v_missing int;
  v_trusted boolean;
  v_status text;
begin
  select * into v_plan from public.training_plans
  where id = p_plan_id and seller_id = v_uid
  for update;
  if v_plan.id is null then raise exception 'Plan not found'; end if;
  if v_plan.status not in ('draft', 'rejected') then
    raise exception 'Only drafts can be submitted';
  end if;

  select count(*),
         count(*) filter (where kind = 'workout'),
         count(*) filter (where kind = 'workout' and jsonb_array_length(exercises) = 0)
    into v_days, v_workouts, v_empty
  from public.training_plan_days where plan_id = p_plan_id;
  if v_days <> v_plan.day_count then raise exception 'Plan days are incomplete'; end if;
  if v_workouts = 0 then raise exception 'Add at least one workout day'; end if;
  if v_empty > 0 then raise exception 'Every workout day needs at least one exercise'; end if;

  select count(distinct lower(trim(exercise.value ->> 'name'))) into v_missing
  from public.training_plan_days d
  cross join lateral jsonb_array_elements(d.exercises) as exercise(value)
  where d.plan_id = p_plan_id and d.kind = 'workout'
    and not exists (
      select 1
      from public.training_plan_exercise_videos v
      join public.media_assets a on a.id = v.video_asset_id
      where v.plan_id = p_plan_id
        and v.exercise_key = lower(trim(exercise.value ->> 'name'))
        and a.status not in ('pending', 'failed', 'quarantined')
    );
  if v_missing > 0 then
    raise exception 'Every exercise needs an explanation video (% missing)', v_missing;
  end if;

  v_trusted := v_plan.published_at is not null or exists (
    select 1 from public.training_plans other
    where other.seller_id = v_uid and other.id <> p_plan_id and other.published_at is not null
      and other.status <> 'removed'
  );
  v_status := case when v_trusted then 'published' else 'in_review' end;

  perform set_config('gymfeed.plan_server_write', 'on', true);
  update public.training_plans set
    status = v_status,
    review_note = '',
    version = case when v_status = 'published' and published_at is not null then version + 1 else version end,
    published_at = case when v_status = 'published' then coalesce(published_at, now()) else published_at end
  where id = p_plan_id;
  return v_status;
end;
$$;

-- Admins review in the app; the SQL editor (no auth.uid()) keeps working.
create or replace function public.review_training_plan(p_plan_id uuid, p_approve boolean, p_note text default '')
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text := case when p_approve then 'published' else 'rejected' end;
begin
  if auth.uid() is not null and not public.is_app_admin() then
    raise exception 'Only GymFeed admins can review plans';
  end if;
  if not p_approve and trim(coalesce(p_note, '')) = '' then
    raise exception 'Tell the creator what to change';
  end if;
  perform set_config('gymfeed.plan_server_write', 'on', true);
  update public.training_plans set
    status = v_status,
    review_note = coalesce(trim(p_note), ''),
    published_at = case when p_approve then coalesce(published_at, now()) else published_at end
  where id = p_plan_id and status = 'in_review';
  if not found then raise exception 'Plan is not waiting for review'; end if;
  return v_status;
end;
$$;

revoke execute on function public.is_app_admin() from public, anon;
grant execute on function public.is_app_admin() to authenticated;
revoke execute on function public.save_training_plan(uuid, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.save_training_plan(uuid, jsonb, jsonb, jsonb) to authenticated;
revoke execute on function public.submit_training_plan(uuid) from public, anon;
grant execute on function public.submit_training_plan(uuid) to authenticated;
revoke execute on function public.review_training_plan(uuid, boolean, text) from public, anon;
grant execute on function public.review_training_plan(uuid, boolean, text) to authenticated;
