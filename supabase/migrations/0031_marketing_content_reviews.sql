-- Human approval decisions imported from the GymFeed marketing review sheet.
-- The worker uses this table as the idempotency and audit boundary so a sheet
-- row cannot approve, publish, or regenerate the same revision twice.

create table if not exists public.marketing_content_reviews (
  id uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.marketing_content (id) on delete cascade,
  revision int not null check (revision > 0),
  decision text not null check (decision in ('approve', 'reject')),
  instructions text not null default '',
  source text not null default 'google_sheets',
  source_ref text,
  status text not null default 'pending' check (status in ('pending', 'processed', 'failed')),
  result jsonb not null default '{}'::jsonb,
  error text,
  processed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (content_id, revision)
);

create index if not exists marketing_content_reviews_status_created_idx
  on public.marketing_content_reviews (status, created_at);

drop trigger if exists touch_marketing_content_reviews on public.marketing_content_reviews;
create trigger touch_marketing_content_reviews
before update on public.marketing_content_reviews
for each row execute function public.marketing_touch_updated_at();

alter table public.marketing_content_reviews enable row level security;

revoke all on table public.marketing_content_reviews from anon, authenticated;
grant all on table public.marketing_content_reviews to service_role;
