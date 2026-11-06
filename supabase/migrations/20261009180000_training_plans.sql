-- Community training plans, phase 1: anyone can build a 1-31 day plan, publish it
-- for free, and other users add it to their Train calendar. Paid plans, purchases
-- and seller payouts arrive in later migrations (see docs/PLAN_MARKETPLACE.md).
--
-- Moderation: a seller's first plan waits in 'in_review'. The founder approves it
-- from the SQL editor with:  select public.review_training_plan('<plan id>', true, '');
-- Once a seller has an approved plan, later submissions publish immediately.

create table if not exists public.training_plans (
  id                   uuid primary key default gen_random_uuid(),
  seller_id            uuid not null references public.profiles (id) on delete cascade,
  title                text not null check (char_length(title) between 3 and 80),
  description          text not null default '' check (char_length(description) <= 2000),
  goal                 text not null default 'general'
                       check (goal in ('strength', 'muscle', 'fat_loss', 'conditioning', 'beginner', 'general')),
  level                text not null default 'intermediate'
                       check (level in ('beginner', 'intermediate', 'advanced')),
  equipment            text not null default 'gym'
                       check (equipment in ('gym', 'dumbbells', 'home', 'none')),
  day_count            int not null default 1 check (day_count between 1 and 31),
  -- Phase 1 sells nothing. The paid-plans migration widens this to (0, 999).
  price_cents          int not null default 0 constraint training_plans_price_phase1 check (price_cents = 0),
  cover_asset_id       uuid references public.media_assets (id) on delete set null,
  intro_video_asset_id uuid references public.media_assets (id) on delete set null,
  status               text not null default 'draft'
                       check (status in ('draft', 'in_review', 'published', 'rejected', 'removed')),
  review_note          text not null default '',
  version              int not null default 1,
  enrollment_count     int not null default 0,
  rating_avg           numeric(3, 2),
  rating_count         int not null default 0,
  published_at         timestamptz,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now()
);

create index if not exists training_plans_store_idx
  on public.training_plans (status, enrollment_count desc, published_at desc);
create index if not exists training_plans_seller_idx
  on public.training_plans (seller_id, updated_at desc);

-- One row per plan day. exercises uses the app's RoutineExercise JSON shape:
-- [{"name", "setCount", "defaultWeightKg", "defaultReps", "setTargets": [{"weightKg", "reps"}]}]
create table if not exists public.training_plan_days (
  plan_id    uuid not null references public.training_plans (id) on delete cascade,
  day        int not null check (day between 1 and 31),
  kind       text not null default 'workout' check (kind in ('workout', 'rest')),
  title      text not null default '' check (char_length(title) <= 80),
  notes      text not null default '' check (char_length(notes) <= 1000),
  exercises  jsonb not null default '[]'::jsonb
             check (jsonb_typeof(exercises) = 'array' and jsonb_array_length(exercises) <= 30),
  primary key (plan_id, day)
);

create table if not exists public.training_plan_enrollments (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles (id) on delete cascade,
  plan_id     uuid not null references public.training_plans (id) on delete cascade,
  version     int not null,
  start_date  date not null,
  mode        text not null default 'consecutive' check (mode in ('consecutive', 'weekdays')),
  weekdays    smallint[] not null default '{}'
              check (weekdays <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[]),
  status      text not null default 'active' check (status in ('active', 'completed', 'removed')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, plan_id),
  check (mode = 'consecutive' or cardinality(weekdays) > 0)
);

create index if not exists training_plan_enrollments_user_idx
  on public.training_plan_enrollments (user_id, status, updated_at desc);

alter table public.training_plans enable row level security;
alter table public.training_plan_days enable row level security;
alter table public.training_plan_enrollments enable row level security;

-- Published plans are public to signed-in users; sellers always see their own.
drop policy if exists "read published or own plans" on public.training_plans;
create policy "read published or own plans"
  on public.training_plans for select
  to authenticated
  using (status = 'published' or seller_id = auth.uid());

-- Writes go through save_training_plan / submit_training_plan, except two seller
-- actions guarded by the trigger below: unpublish for editing and remove.
drop policy if exists "seller updates own plan" on public.training_plans;
create policy "seller updates own plan"
  on public.training_plans for update
  to authenticated
  using (seller_id = auth.uid())
  with check (seller_id = auth.uid());

drop policy if exists "seller deletes unpublished plan" on public.training_plans;
create policy "seller deletes unpublished plan"
  on public.training_plans for delete
  to authenticated
  using (seller_id = auth.uid() and status in ('draft', 'rejected'));

drop policy if exists "read days of visible plans" on public.training_plan_days;
create policy "read days of visible plans"
  on public.training_plan_days for select
  to authenticated
  using (exists (
    select 1 from public.training_plans p
    where p.id = plan_id and (p.status = 'published' or p.seller_id = auth.uid())
  ));

drop policy if exists "own enrollments" on public.training_plan_enrollments;
create policy "own enrollments"
  on public.training_plan_enrollments for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "enroll in published plan" on public.training_plan_enrollments;
create policy "enroll in published plan"
  on public.training_plan_enrollments for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.training_plans p
      where p.id = plan_id and (p.status = 'published' or p.seller_id = auth.uid())
    )
  );

drop policy if exists "update own enrollment" on public.training_plan_enrollments;
create policy "update own enrollment"
  on public.training_plan_enrollments for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- A seller may only move their plan back to draft (to edit it) or remove it.
-- Everything else (review status, counters, ratings) is server-owned.
create or replace function public.guard_training_plan_update()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  if auth.uid() is null or current_setting('gymfeed.plan_server_write', true) = 'on' then
    return new;
  end if;
  if new.status is distinct from old.status and new.status not in ('draft', 'removed') then
    raise exception 'Plans are published through submit_training_plan';
  end if;
  new.seller_id := old.seller_id;
  new.version := old.version;
  new.review_note := old.review_note;
  new.enrollment_count := old.enrollment_count;
  new.rating_avg := old.rating_avg;
  new.rating_count := old.rating_count;
  new.published_at := old.published_at;
  new.price_cents := old.price_cents;
  return new;
end;
$$;

drop trigger if exists training_plans_guard on public.training_plans;
create trigger training_plans_guard
before update on public.training_plans
for each row execute function public.guard_training_plan_update();

-- Creates or replaces a draft and all its days in one transaction.
-- p_fields: {title, description, goal, level, equipment}
-- p_days:   [{kind, title, notes, exercises}] in day order (1..N)
create or replace function public.save_training_plan(p_plan_id uuid, p_fields jsonb, p_days jsonb)
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
begin
  if v_uid is null then raise exception 'Sign in to create plans'; end if;
  if jsonb_typeof(p_days) is distinct from 'array' or v_count < 1 or v_count > 31 then
    raise exception 'A plan has between 1 and 31 days';
  end if;

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

  return v_id;
end;
$$;

-- Validates a draft and either publishes it (trusted seller or previously
-- published plan) or queues it for the founder's review. Returns the new status.
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

-- Founder-only moderation; not exposed to app users.
create or replace function public.review_training_plan(p_plan_id uuid, p_approve boolean, p_note text default '')
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_status text := case when p_approve then 'published' else 'rejected' end;
begin
  perform set_config('gymfeed.plan_server_write', 'on', true);
  update public.training_plans set
    status = v_status,
    review_note = coalesce(p_note, ''),
    published_at = case when p_approve then coalesce(published_at, now()) else published_at end
  where id = p_plan_id and status = 'in_review';
  if not found then raise exception 'Plan is not waiting for review'; end if;
  return v_status;
end;
$$;

create or replace function public.bump_training_plan_enrollment_count()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  perform set_config('gymfeed.plan_server_write', 'on', true);
  update public.training_plans
  set enrollment_count = enrollment_count + 1
  where id = new.plan_id and seller_id <> new.user_id;
  return new;
end;
$$;

drop trigger if exists training_plan_enrollments_count on public.training_plan_enrollments;
create trigger training_plan_enrollments_count
after insert on public.training_plan_enrollments
for each row execute function public.bump_training_plan_enrollment_count();

create or replace function public.touch_training_plan_enrollment()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  new.updated_at := now();
  new.user_id := old.user_id;
  new.plan_id := old.plan_id;
  return new;
end;
$$;

drop trigger if exists training_plan_enrollments_touch on public.training_plan_enrollments;
create trigger training_plan_enrollments_touch
before update on public.training_plan_enrollments
for each row execute function public.touch_training_plan_enrollment();

revoke execute on function public.guard_training_plan_update() from public, anon, authenticated;
revoke execute on function public.bump_training_plan_enrollment_count() from public, anon, authenticated;
revoke execute on function public.touch_training_plan_enrollment() from public, anon, authenticated;
revoke execute on function public.review_training_plan(uuid, boolean, text) from public, anon, authenticated;
revoke execute on function public.save_training_plan(uuid, jsonb, jsonb) from public, anon;
revoke execute on function public.submit_training_plan(uuid) from public, anon;
grant execute on function public.save_training_plan(uuid, jsonb, jsonb) to authenticated;
grant execute on function public.submit_training_plan(uuid) to authenticated;
