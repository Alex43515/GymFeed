-- GymFeed autonomous marketing system.
--
-- n8n and the marketing worker use the service-role key, so the operational
-- tables intentionally have RLS enabled without client policies. Product
-- conversion events are written by security-definer triggers and the verified
-- RevenueCat webhook instead of trusting client-submitted revenue data.

do $$ begin
  create type public.marketing_content_type as enum ('video', 'image', 'carousel');
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.marketing_content_status as enum (
    'planned',
    'generating',
    'generated',
    'qa_failed',
    'awaiting_approval',
    'approved',
    'scheduled',
    'published',
    'skipped',
    'failed'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.marketing_run_status as enum ('running', 'succeeded', 'failed', 'skipped');
exception when duplicate_object then null;
end $$;

create table if not exists public.marketing_brand_config (
  id text primary key default 'gymfeed',
  enabled boolean not null default false,
  manual_approval_required boolean not null default true,
  minimum_qa_score int not null default 85 check (minimum_qa_score between 0 and 100),
  target_markets text[] not null default array['US', 'CA'],
  timezone text not null default 'America/New_York',
  daily_video_target int not null default 1 check (daily_video_target between 0 and 10),
  daily_instagram_target int not null default 1 check (daily_instagram_target between 0 and 10),
  brand jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.marketing_brand_config (id, brand)
values (
  'gymfeed',
  jsonb_build_object(
    'name', 'GymFeed',
    'positioning', 'An AI-powered fitness app that helps people plan, track, and improve their training and nutrition.',
    'voice', array['direct', 'useful', 'encouraging', 'evidence-aware', 'never body-shaming'],
    'visual_direction', 'Modern fitness technology; candid and human; high contrast; avoid generic gym-quote aesthetics.',
    'default_ctas', array['Try GymFeed', 'Build your plan in GymFeed', 'Track it in GymFeed'],
    'prohibited_claims', array[
      'guaranteed outcomes',
      'fabricated testimonials',
      'unsafe exercise or nutrition advice',
      'unverified medical claims',
      'before-and-after transformations presented as real'
    ]
  )
)
on conflict (id) do nothing;

create table if not exists public.marketing_runs (
  id uuid primary key default gen_random_uuid(),
  workflow text not null,
  status public.marketing_run_status not null default 'running',
  idempotency_key text unique,
  input jsonb not null default '{}'::jsonb,
  output jsonb not null default '{}'::jsonb,
  error text,
  estimated_cost_usd numeric(12, 6) not null default 0 check (estimated_cost_usd >= 0),
  actual_cost_usd numeric(12, 6) check (actual_cost_usd is null or actual_cost_usd >= 0),
  started_at timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists marketing_runs_workflow_started_idx
  on public.marketing_runs (workflow, started_at desc);

create table if not exists public.marketing_research (
  id uuid primary key default gen_random_uuid(),
  run_id uuid references public.marketing_runs (id) on delete set null,
  summary text not null,
  trends jsonb not null default '[]'::jsonb,
  sources jsonb not null default '[]'::jsonb,
  valid_until timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists marketing_research_created_idx
  on public.marketing_research (created_at desc);

create table if not exists public.marketing_content (
  id uuid primary key default gen_random_uuid(),
  content_key text not null unique,
  run_id uuid references public.marketing_runs (id) on delete set null,
  master_content_id uuid references public.marketing_content (id) on delete set null,
  content_type public.marketing_content_type not null,
  status public.marketing_content_status not null default 'planned',
  topic text not null,
  concept text not null,
  hook text not null default '',
  decision jsonb not null default '{}'::jsonb,
  provider text,
  provider_task_id text,
  asset_urls text[] not null default '{}',
  thumbnail_url text,
  qa_score int check (qa_score is null or qa_score between 0 and 100),
  qa jsonb not null default '{}'::jsonb,
  failure_reason text,
  approved_by uuid references public.profiles (id) on delete set null,
  approved_at timestamptz,
  scheduled_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists marketing_content_status_created_idx
  on public.marketing_content (status, created_at desc);
create index if not exists marketing_content_topic_idx
  on public.marketing_content (topic, created_at desc);

create table if not exists public.marketing_publications (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.marketing_content (id) on delete cascade,
  platform text not null check (platform in ('instagram', 'tiktok', 'youtube')),
  account_ref text,
  status text not null default 'pending'
    check (status in ('pending', 'scheduled', 'publishing', 'published', 'failed', 'deleted')),
  platform_copy jsonb not null default '{}'::jsonb,
  external_post_id text,
  external_url text,
  provider_request_id text,
  scheduled_at timestamptz,
  published_at timestamptz,
  metrics jsonb not null default '{}'::jsonb,
  last_metrics_sync_at timestamptz,
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (content_id, platform)
);
create index if not exists marketing_publications_platform_published_idx
  on public.marketing_publications (platform, published_at desc);

create table if not exists public.marketing_attributions (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  content_id uuid references public.marketing_content (id) on delete set null,
  publication_id uuid references public.marketing_publications (id) on delete set null,
  attribution_key text not null,
  source text,
  medium text,
  campaign text,
  session_id text,
  properties jsonb not null default '{}'::jsonb,
  claimed_at timestamptz not null default now()
);
create index if not exists marketing_attributions_key_idx
  on public.marketing_attributions (attribution_key);

create table if not exists public.marketing_events (
  id bigint generated by default as identity primary key,
  user_id uuid references public.profiles (id) on delete set null,
  content_id uuid references public.marketing_content (id) on delete set null,
  publication_id uuid references public.marketing_publications (id) on delete set null,
  event_name text not null,
  source text not null default 'product',
  platform text,
  attribution_key text,
  session_id text,
  value_usd numeric(12, 4) check (value_usd is null or value_usd >= 0),
  currency text not null default 'USD',
  properties jsonb not null default '{}'::jsonb,
  dedupe_key text unique,
  occurred_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index if not exists marketing_events_name_occurred_idx
  on public.marketing_events (event_name, occurred_at desc);
create index if not exists marketing_events_content_occurred_idx
  on public.marketing_events (content_id, occurred_at desc)
  where content_id is not null;
create index if not exists marketing_events_user_occurred_idx
  on public.marketing_events (user_id, occurred_at desc)
  where user_id is not null;

-- Authenticated clients may claim only their own first-touch attribution key.
-- The function resolves the public key server-side and backfills the user's
-- signup event so later conversion analysis has a stable content join.
create or replace function public.claim_marketing_attribution(
  p_attribution_key text,
  p_source text default null,
  p_medium text default null,
  p_campaign text default null,
  p_session_id text default null,
  p_properties jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_content_id uuid;
  v_publication_id uuid;
  v_attribution_key text;
  v_source text;
begin
  if v_user_id is null then
    raise exception 'authentication required';
  end if;
  if p_attribution_key is null or length(btrim(p_attribution_key)) < 4 then
    raise exception 'invalid attribution key';
  end if;

  select id into v_content_id
    from public.marketing_content
   where content_key = p_attribution_key;

  if v_content_id is null then
    select id, content_id into v_publication_id, v_content_id
      from public.marketing_publications
     where provider_request_id = p_attribution_key
        or external_post_id = p_attribution_key
     order by created_at desc
     limit 1;
  end if;

  if v_content_id is null then
    raise exception 'unknown attribution key';
  end if;

  insert into public.marketing_attributions (
    user_id, content_id, publication_id, attribution_key,
    source, medium, campaign, session_id, properties
  ) values (
    v_user_id, v_content_id, v_publication_id, p_attribution_key,
    p_source, p_medium, p_campaign, p_session_id, coalesce(p_properties, '{}'::jsonb)
  )
  on conflict (user_id) do nothing;

  -- Preserve the user's first touch if this RPC is called again later.
  select content_id, publication_id, attribution_key, source
    into v_content_id, v_publication_id, v_attribution_key, v_source
    from public.marketing_attributions
   where user_id = v_user_id;

  update public.marketing_events
     set content_id = coalesce(content_id, v_content_id),
         publication_id = coalesce(publication_id, v_publication_id),
         attribution_key = coalesce(attribution_key, v_attribution_key),
         platform = coalesce(platform, v_source)
   where user_id = v_user_id and event_name = 'signup';
end;
$$;

revoke execute on function public.claim_marketing_attribution(text, text, text, text, text, jsonb)
  from public, anon;
grant execute on function public.claim_marketing_attribution(text, text, text, text, text, jsonb)
  to authenticated;

create table if not exists public.marketing_learnings (
  id uuid primary key default gen_random_uuid(),
  run_id uuid references public.marketing_runs (id) on delete set null,
  status text not null default 'hypothesis'
    check (status in ('hypothesis', 'validated', 'disproven', 'retired')),
  pattern text not null,
  supporting_evidence jsonb not null default '[]'::jsonb,
  sample_size int not null default 0 check (sample_size >= 0),
  confidence numeric(4, 3) not null default 0 check (confidence between 0 and 1),
  recommended_action text not null default '',
  more_testing_required boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists marketing_learnings_status_confidence_idx
  on public.marketing_learnings (status, confidence desc, created_at desc);

create table if not exists public.marketing_budgets (
  month date primary key check (month = date_trunc('month', month)::date),
  currency text not null default 'USD',
  provider_limits jsonb not null,
  total_limit numeric(12, 2) not null check (total_limit >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.marketing_budgets (month, provider_limits, total_limit)
values (
  date_trunc('month', now())::date,
  '{"openai":25,"gemini":15,"byteplus":100,"blotato":29,"infrastructure":10}'::jsonb,
  180
)
on conflict (month) do nothing;

create table if not exists public.marketing_cost_ledger (
  id uuid primary key default gen_random_uuid(),
  budget_month date not null references public.marketing_budgets (month) on delete restrict,
  provider text not null,
  run_id uuid references public.marketing_runs (id) on delete set null,
  content_id uuid references public.marketing_content (id) on delete set null,
  status text not null default 'reserved' check (status in ('reserved', 'settled', 'released')),
  estimated_cost_usd numeric(12, 6) not null check (estimated_cost_usd >= 0),
  actual_cost_usd numeric(12, 6) check (actual_cost_usd is null or actual_cost_usd >= 0),
  external_ref text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  settled_at timestamptz
);
create index if not exists marketing_cost_ledger_month_provider_idx
  on public.marketing_cost_ledger (budget_month, provider, status);

-- Atomic reservation prevents concurrent n8n executions from overspending the
-- monthly total or an individual provider limit.
create or replace function public.reserve_marketing_cost(
  p_provider text,
  p_estimated_cost_usd numeric,
  p_run_id uuid default null,
  p_content_id uuid default null,
  p_metadata jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_month date := date_trunc('month', now())::date;
  v_budget public.marketing_budgets%rowtype;
  v_total_spend numeric;
  v_provider_spend numeric;
  v_provider_limit numeric;
  v_id uuid;
begin
  if p_provider is null or btrim(p_provider) = '' then
    raise exception 'provider is required';
  end if;
  if p_estimated_cost_usd is null or p_estimated_cost_usd < 0 then
    raise exception 'estimated cost must be non-negative';
  end if;

  -- Carry the most recent limits forward at month rollover. This keeps the
  -- scheduler operating while still requiring every spend to fit a budget.
  insert into public.marketing_budgets (month, currency, provider_limits, total_limit)
  select v_month, currency, provider_limits, total_limit
    from public.marketing_budgets
   order by month desc
   limit 1
  on conflict (month) do nothing;

  select * into v_budget
    from public.marketing_budgets
   where month = v_month
   for update;
  if not found then
    raise exception 'no marketing budget configured for %', v_month;
  end if;

  v_provider_limit := nullif(v_budget.provider_limits ->> p_provider, '')::numeric;
  if v_provider_limit is null then
    raise exception 'no provider budget configured for %', p_provider;
  end if;

  select coalesce(sum(
    case status
      when 'settled' then coalesce(actual_cost_usd, estimated_cost_usd)
      when 'reserved' then estimated_cost_usd
      else 0
    end
  ), 0)
  into v_total_spend
  from public.marketing_cost_ledger
  where budget_month = v_month;

  select coalesce(sum(
    case status
      when 'settled' then coalesce(actual_cost_usd, estimated_cost_usd)
      when 'reserved' then estimated_cost_usd
      else 0
    end
  ), 0)
  into v_provider_spend
  from public.marketing_cost_ledger
  where budget_month = v_month and provider = p_provider;

  if v_total_spend + p_estimated_cost_usd > v_budget.total_limit then
    raise exception 'monthly marketing budget exceeded';
  end if;
  if v_provider_spend + p_estimated_cost_usd > v_provider_limit then
    raise exception '% provider budget exceeded', p_provider;
  end if;

  insert into public.marketing_cost_ledger (
    budget_month, provider, run_id, content_id, estimated_cost_usd, metadata
  ) values (
    v_month, p_provider, p_run_id, p_content_id, p_estimated_cost_usd, coalesce(p_metadata, '{}'::jsonb)
  ) returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.settle_marketing_cost(
  p_reservation_id uuid,
  p_actual_cost_usd numeric,
  p_external_ref text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_entry public.marketing_cost_ledger%rowtype;
  v_budget public.marketing_budgets%rowtype;
  v_total_spend numeric;
  v_provider_spend numeric;
  v_provider_limit numeric;
  v_extra numeric;
begin
  if p_actual_cost_usd is null or p_actual_cost_usd < 0 then
    raise exception 'actual cost must be non-negative';
  end if;

  select * into v_entry
    from public.marketing_cost_ledger
   where id = p_reservation_id and status = 'reserved'
   for update;
  if not found then
    raise exception 'active reservation not found';
  end if;

  select * into v_budget
    from public.marketing_budgets
   where month = v_entry.budget_month
   for update;
  if not found then
    raise exception 'marketing budget not found';
  end if;

  v_extra := greatest(0, p_actual_cost_usd - v_entry.estimated_cost_usd);
  if v_extra > 0 then
    v_provider_limit := nullif(v_budget.provider_limits ->> v_entry.provider, '')::numeric;
    select coalesce(sum(
      case status
        when 'settled' then coalesce(actual_cost_usd, estimated_cost_usd)
        when 'reserved' then estimated_cost_usd
        else 0
      end
    ), 0) into v_total_spend
      from public.marketing_cost_ledger
     where budget_month = v_entry.budget_month;
    select coalesce(sum(
      case status
        when 'settled' then coalesce(actual_cost_usd, estimated_cost_usd)
        when 'reserved' then estimated_cost_usd
        else 0
      end
    ), 0) into v_provider_spend
      from public.marketing_cost_ledger
     where budget_month = v_entry.budget_month and provider = v_entry.provider;

    if v_total_spend + v_extra > v_budget.total_limit
       or v_provider_limit is null
       or v_provider_spend + v_extra > v_provider_limit then
      raise exception 'actual cost would exceed marketing budget';
    end if;
  end if;

  update public.marketing_cost_ledger
     set status = 'settled',
         actual_cost_usd = p_actual_cost_usd,
         external_ref = coalesce(p_external_ref, external_ref),
         settled_at = now()
   where id = p_reservation_id and status = 'reserved';

end;
$$;

create or replace function public.release_marketing_cost(p_reservation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.marketing_cost_ledger
     set status = 'released', settled_at = now()
   where id = p_reservation_id and status = 'reserved';
end;
$$;

revoke execute on function public.reserve_marketing_cost(text, numeric, uuid, uuid, jsonb)
  from public, anon, authenticated;
revoke execute on function public.settle_marketing_cost(uuid, numeric, text)
  from public, anon, authenticated;
revoke execute on function public.release_marketing_cost(uuid)
  from public, anon, authenticated;
grant execute on function public.reserve_marketing_cost(text, numeric, uuid, uuid, jsonb)
  to service_role;
grant execute on function public.settle_marketing_cost(uuid, numeric, text)
  to service_role;
grant execute on function public.release_marketing_cost(uuid)
  to service_role;

create or replace function public.marketing_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists touch_marketing_brand_config on public.marketing_brand_config;
create trigger touch_marketing_brand_config before update on public.marketing_brand_config
for each row execute function public.marketing_touch_updated_at();

drop trigger if exists touch_marketing_content on public.marketing_content;
create trigger touch_marketing_content before update on public.marketing_content
for each row execute function public.marketing_touch_updated_at();

drop trigger if exists touch_marketing_publications on public.marketing_publications;
create trigger touch_marketing_publications before update on public.marketing_publications
for each row execute function public.marketing_touch_updated_at();

drop trigger if exists touch_marketing_learnings on public.marketing_learnings;
create trigger touch_marketing_learnings before update on public.marketing_learnings
for each row execute function public.marketing_touch_updated_at();

drop trigger if exists touch_marketing_budgets on public.marketing_budgets;
create trigger touch_marketing_budgets before update on public.marketing_budgets
for each row execute function public.marketing_touch_updated_at();

-- First-party product outcomes. These make the learning loop useful even before
-- GA4 is connected and cannot be forged through the client API.
create or replace function public.record_marketing_signup()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.marketing_events (user_id, event_name, dedupe_key, occurred_at)
  values (new.id, 'signup', 'signup:' || new.id::text, coalesce(new.created_at, now()))
  on conflict (dedupe_key) do nothing;
  return new;
end;
$$;

drop trigger if exists record_profile_signup_for_marketing on public.profiles;
create trigger record_profile_signup_for_marketing
after insert on public.profiles
for each row execute function public.record_marketing_signup();

create or replace function public.record_marketing_onboarding_completion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.age > 0
     and new.height_cm > 0
     and new.weight_kg > 0
     and btrim(new.workout_level) <> ''
     and btrim(new.goals) <> ''
     and btrim(new.workouts) <> '' then
    insert into public.marketing_events (user_id, event_name, dedupe_key)
    values (new.id, 'onboarding_completed', 'onboarding_completed:' || new.id::text)
    on conflict (dedupe_key) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists record_profile_onboarding_for_marketing on public.profile_private;
create trigger record_profile_onboarding_for_marketing
after insert or update on public.profile_private
for each row execute function public.record_marketing_onboarding_completion();

create or replace function public.record_marketing_first_workout()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.user_id is null then
    return new;
  end if;
  insert into public.marketing_events (user_id, event_name, dedupe_key, properties)
  values (
    new.user_id,
    'first_workout',
    'first_workout:' || new.user_id::text,
    jsonb_build_object('workout_entry_id', new.id)
  )
  on conflict (dedupe_key) do nothing;
  return new;
end;
$$;

drop trigger if exists record_first_workout_for_marketing on public.workout_entries;
create trigger record_first_workout_for_marketing
after insert on public.workout_entries
for each row execute function public.record_marketing_first_workout();

-- Backfill pre-existing users so the first weekly review is not blind to the
-- app's current acquisition and activation baseline.
insert into public.marketing_events (user_id, event_name, dedupe_key, occurred_at)
select id, 'signup', 'signup:' || id::text, created_at
  from public.profiles
on conflict (dedupe_key) do nothing;

insert into public.marketing_events (user_id, event_name, dedupe_key)
select id, 'onboarding_completed', 'onboarding_completed:' || id::text
  from public.profile_private
 where age > 0
   and height_cm > 0
   and weight_kg > 0
   and btrim(workout_level) <> ''
   and btrim(goals) <> ''
   and btrim(workouts) <> ''
on conflict (dedupe_key) do nothing;

insert into public.marketing_events (user_id, event_name, dedupe_key, occurred_at, properties)
select distinct on (user_id)
       user_id,
       'first_workout',
       'first_workout:' || user_id::text,
       coalesce(date, created_at),
       jsonb_build_object('workout_entry_id', id)
  from public.workout_entries
 where user_id is not null
 order by user_id, coalesce(date, created_at), created_at
on conflict (dedupe_key) do nothing;

revoke execute on function public.record_marketing_signup() from public, anon, authenticated;
revoke execute on function public.record_marketing_onboarding_completion() from public, anon, authenticated;
revoke execute on function public.record_marketing_first_workout() from public, anon, authenticated;

alter table public.marketing_brand_config enable row level security;
alter table public.marketing_runs enable row level security;
alter table public.marketing_research enable row level security;
alter table public.marketing_content enable row level security;
alter table public.marketing_publications enable row level security;
alter table public.marketing_attributions enable row level security;
alter table public.marketing_events enable row level security;
alter table public.marketing_learnings enable row level security;
alter table public.marketing_budgets enable row level security;
alter table public.marketing_cost_ledger enable row level security;

-- Public URLs are required by Blotato and the direct social publishing APIs.
-- Only the service-role marketing worker can write because no object policies
-- grant client inserts/updates/deletes.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'marketing-assets',
  'marketing-assets',
  true,
  536870912,
  array['image/png', 'image/jpeg', 'image/webp', 'video/mp4']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

comment on table public.marketing_content is
  'Versioned content decisions and generated asset state for the GymFeed marketing system.';
comment on table public.marketing_events is
  'First-party acquisition, activation, and subscription outcomes used by the marketing learning loop.';
comment on function public.reserve_marketing_cost(text, numeric, uuid, uuid, jsonb) is
  'Atomically reserves provider spend under both provider and total monthly limits.';
