-- Community training plans, phase 2b: cover image + intro video on every plan,
-- ratings from people who follow a plan, admin-featured plans, and plan reports.
--
-- Cover images live in the public `images` storage bucket (same uploader as
-- posts); intro and exercise videos are Bunny Stream media_assets.

alter table public.training_plans
  add column if not exists cover_image_url text not null default '',
  add column if not exists is_featured boolean not null default false;

create index if not exists training_plans_featured_idx
  on public.training_plans (is_featured, published_at desc)
  where status = 'published' and is_featured;

-- Sellers may only move their own plan back to draft (to edit it) or remove
-- it. Every content change goes through save_training_plan, so a published
-- plan can never be edited past review.
create or replace function public.guard_training_plan_update()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
declare
  v_status text := new.status;
begin
  if auth.uid() is null or current_setting('gymfeed.plan_server_write', true) = 'on' then
    new.updated_at := now();
    return new;
  end if;
  if v_status is distinct from old.status and v_status not in ('draft', 'removed') then
    raise exception 'Plans are published through submit_training_plan';
  end if;
  new := old;
  new.status := v_status;
  new.updated_at := now();
  return new;
end;
$$;

-- p_fields: {title, description, goal, level, equipment, cover_image_url, intro_video_asset_id}
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
  v_cover text := coalesce(trim(p_fields ->> 'cover_image_url'), '');
  v_intro uuid := nullif(trim(coalesce(p_fields ->> 'intro_video_asset_id', '')), '')::uuid;
begin
  if v_uid is null then raise exception 'Sign in to create plans'; end if;
  if jsonb_typeof(p_days) is distinct from 'array' or v_count < 1 or v_count > 31 then
    raise exception 'A plan has between 1 and 31 days';
  end if;
  if jsonb_typeof(coalesce(p_videos, '[]'::jsonb)) <> 'array' then
    raise exception 'Videos must be a list';
  end if;
  if v_cover <> '' and v_cover !~ ('^https://[^/]+/storage/v1/object/public/images/' || v_uid::text || '/') then
    raise exception 'The cover image must be your own upload';
  end if;

  select count(*) into v_foreign
  from (
    select nullif(item.value ->> 'video_asset_id', '')::uuid as asset_id
    from jsonb_array_elements(coalesce(p_videos, '[]'::jsonb)) as item(value)
    union all
    select v_intro where v_intro is not null
  ) wanted
  left join public.media_assets a on a.id = wanted.asset_id
  where a.id is null or a.owner_id <> v_uid or a.kind <> 'video';
  if v_foreign > 0 then raise exception 'Exercise videos must be your own uploads'; end if;

  perform set_config('gymfeed.plan_server_write', 'on', true);
  if v_id is null then
    insert into public.training_plans (
      seller_id, title, description, goal, level, equipment, day_count,
      cover_image_url, intro_video_asset_id)
    values (
      v_uid,
      trim(p_fields ->> 'title'),
      coalesce(trim(p_fields ->> 'description'), ''),
      coalesce(p_fields ->> 'goal', 'general'),
      coalesce(p_fields ->> 'level', 'intermediate'),
      coalesce(p_fields ->> 'equipment', 'gym'),
      v_count,
      v_cover,
      v_intro
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
      cover_image_url = v_cover,
      intro_video_asset_id = v_intro,
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

-- Phase 2 checks plus: a cover image and a working intro video.
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
  if v_plan.cover_image_url = '' then raise exception 'Add a cover image'; end if;
  if not exists (
    select 1 from public.media_assets a
    where a.id = v_plan.intro_video_asset_id
      and a.status not in ('pending', 'failed', 'quarantined')
  ) then
    raise exception 'Add an intro video';
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

create or replace function public.set_training_plan_featured(p_plan_id uuid, p_featured boolean)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is not null and not public.is_app_admin() then
    raise exception 'Only GymFeed admins can feature plans';
  end if;
  perform set_config('gymfeed.plan_server_write', 'on', true);
  update public.training_plans set is_featured = p_featured
  where id = p_plan_id and status = 'published';
  if not found then raise exception 'Only published plans can be featured'; end if;
end;
$$;

-- Ratings: one per person, only from people who added the plan to their Train.
create table if not exists public.training_plan_ratings (
  plan_id    uuid not null references public.training_plans (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  rating     smallint not null check (rating between 1 and 5),
  comment    text not null default '' check (char_length(comment) <= 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (plan_id, user_id)
);

create index if not exists training_plan_ratings_plan_idx
  on public.training_plan_ratings (plan_id, updated_at desc);

alter table public.training_plan_ratings enable row level security;

drop policy if exists "read ratings of visible plans" on public.training_plan_ratings;
create policy "read ratings of visible plans"
  on public.training_plan_ratings for select
  to authenticated
  using (exists (
    select 1 from public.training_plans p
    where p.id = plan_id
      and (p.status = 'published' or p.seller_id = auth.uid() or public.is_app_admin())
  ));

drop policy if exists "followers rate plans" on public.training_plan_ratings;
create policy "followers rate plans"
  on public.training_plan_ratings for insert
  to authenticated
  with check (
    user_id = auth.uid()
    and exists (
      select 1 from public.training_plan_enrollments e
      join public.training_plans p on p.id = e.plan_id
      where e.plan_id = training_plan_ratings.plan_id
        and e.user_id = auth.uid()
        and p.seller_id <> auth.uid()
        and p.status = 'published'
    )
  );

drop policy if exists "update own rating" on public.training_plan_ratings;
create policy "update own rating"
  on public.training_plan_ratings for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "delete own rating" on public.training_plan_ratings;
create policy "delete own rating"
  on public.training_plan_ratings for delete
  to authenticated
  using (user_id = auth.uid());

create or replace function public.refresh_training_plan_rating()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_plan uuid := coalesce(new.plan_id, old.plan_id);
begin
  if tg_op = 'UPDATE' then
    new.updated_at := now();
    new.plan_id := old.plan_id;
    new.user_id := old.user_id;
    return new;
  end if;
  return coalesce(new, old);
end;
$$;

create or replace function public.recount_training_plan_rating()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_plan uuid := coalesce(new.plan_id, old.plan_id);
begin
  perform set_config('gymfeed.plan_server_write', 'on', true);
  update public.training_plans p set
    rating_count = stats.total,
    rating_avg = stats.average
  from (
    select count(*)::int as total, round(avg(rating)::numeric, 2) as average
    from public.training_plan_ratings where plan_id = v_plan
  ) stats
  where p.id = v_plan;
  return null;
end;
$$;

drop trigger if exists training_plan_ratings_touch on public.training_plan_ratings;
create trigger training_plan_ratings_touch
before update on public.training_plan_ratings
for each row execute function public.refresh_training_plan_rating();

drop trigger if exists training_plan_ratings_recount on public.training_plan_ratings;
create trigger training_plan_ratings_recount
after insert or update or delete on public.training_plan_ratings
for each row execute function public.recount_training_plan_rating();

-- Plans can be reported like posts and workouts.
alter table public.reports drop constraint if exists reports_content_type_check;
alter table public.reports add constraint reports_content_type_check
  check (content_type in ('post', 'food_post', 'workout', 'account', 'training_plan'));

revoke execute on function public.refresh_training_plan_rating() from public, anon, authenticated;
revoke execute on function public.recount_training_plan_rating() from public, anon, authenticated;
revoke execute on function public.set_training_plan_featured(uuid, boolean) from public, anon;
grant execute on function public.set_training_plan_featured(uuid, boolean) to authenticated;
revoke execute on function public.save_training_plan(uuid, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.save_training_plan(uuid, jsonb, jsonb, jsonb) to authenticated;
revoke execute on function public.submit_training_plan(uuid) from public, anon;
grant execute on function public.submit_training_plan(uuid) to authenticated;
