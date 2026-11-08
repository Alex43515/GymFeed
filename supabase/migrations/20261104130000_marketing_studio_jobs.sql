-- Durable operator jobs and incidents. Browser roles cannot read or write these tables.
create table if not exists public.marketing_studio_jobs (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  content_id uuid references public.marketing_content(id),
  request_key text not null unique,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'queued' check (status in ('queued','running','retry_wait','succeeded','failed','needs_attention','cancelled')),
  attempts integer not null default 0,
  max_attempts integer not null default 3 check (max_attempts between 1 and 5),
  next_run_at timestamptz not null default now(),
  lock_token uuid,
  heartbeat_at timestamptz,
  result jsonb,
  error jsonb,
  created_at timestamptz not null default now(),
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now()
);
create index if not exists marketing_studio_jobs_queue on public.marketing_studio_jobs(next_run_at,created_at)
  where status in ('queued','retry_wait');
create table if not exists public.marketing_studio_events (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references public.marketing_studio_jobs(id),
  content_id uuid references public.marketing_content(id),
  level text not null check (level in ('info','warning','error')),
  stage text not null,
  message text not null,
  detail jsonb not null default '{}'::jsonb,
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists marketing_studio_events_recent on public.marketing_studio_events(created_at desc);
alter table public.marketing_studio_jobs enable row level security;
alter table public.marketing_studio_events enable row level security;
revoke all on public.marketing_studio_jobs, public.marketing_studio_events from anon, authenticated;
grant all on public.marketing_studio_jobs, public.marketing_studio_events to service_role;

create or replace function public.marketing_studio_claim_job()
returns jsonb language plpgsql security invoker set search_path = public as $$
declare v_job public.marketing_studio_jobs;
begin
  -- A lost lease can mean the provider accepted work. Require reconciliation,
  -- rather than submitting a second chargeable request after a worker crash.
  update public.marketing_studio_jobs set status='needs_attention',updated_at=now(),
    error=jsonb_build_object('code','WORKER_INTERRUPTED','category','interrupted','retryable',false,
      'message','Worker heartbeat expired. Reconcile saved provider tasks before retrying.',
      'next_action','Open the content and resume its saved tasks; do not regenerate completed scenes.')
    where status='running' and heartbeat_at < now()-interval '3 minutes';
  select * into v_job from public.marketing_studio_jobs
    where status in ('queued','retry_wait') and next_run_at<=now()
    order by next_run_at,created_at for update skip locked limit 1;
  if not found then return null; end if;
  update public.marketing_studio_jobs set status='running',attempts=attempts+1,
    lock_token=gen_random_uuid(),heartbeat_at=now(),started_at=coalesce(started_at,now()),updated_at=now()
    where id=v_job.id returning * into v_job;
  return to_jsonb(v_job);
end $$;
revoke all on function public.marketing_studio_claim_job() from public,anon,authenticated;
grant execute on function public.marketing_studio_claim_job() to service_role;
