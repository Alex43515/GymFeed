-- Personalized 28-day plans generated once when onboarding is completed.
-- The structured JSON is private health data and is readable only by its owner.

create table if not exists public.starter_plans (
  user_id        uuid primary key references public.profiles (id) on delete cascade,
  status         text not null default 'requested'
                 check (status in ('requested', 'generating', 'ready', 'failed')),
  prompt_version int not null default 1,
  period_start   date,
  period_end     date,
  plan           jsonb not null default '{}'::jsonb,
  raw_workout    text not null default '',
  raw_meal       text not null default '',
  last_error     text not null default '',
  requested_at   timestamptz not null default now(),
  generated_at   timestamptz,
  updated_at     timestamptz not null default now()
);

create index if not exists starter_plans_status_idx
  on public.starter_plans (status, updated_at);

alter table public.starter_plans enable row level security;

drop policy if exists "own starter plan read" on public.starter_plans;
create policy "own starter plan read"
  on public.starter_plans for select
  using (auth.uid() = user_id);

drop policy if exists "request own starter plan" on public.starter_plans;
create policy "request own starter plan"
  on public.starter_plans for insert
  with check (auth.uid() = user_id);

drop policy if exists "update own starter plan" on public.starter_plans;
create policy "update own starter plan"
  on public.starter_plans for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "delete own starter plan" on public.starter_plans;
create policy "delete own starter plan"
  on public.starter_plans for delete
  using (auth.uid() = user_id);

create or replace function public.touch_starter_plan_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists starter_plans_touch_updated_at on public.starter_plans;
create trigger starter_plans_touch_updated_at
before update on public.starter_plans
for each row execute function public.touch_starter_plan_updated_at();

revoke execute on function public.touch_starter_plan_updated_at()
  from public, anon, authenticated;

