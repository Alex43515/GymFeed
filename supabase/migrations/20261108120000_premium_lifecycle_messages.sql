-- Founding launch messages: a welcome email when a user's free Premium days
-- start, and a reminder shortly before they end (email + push + an item in
-- Notifications).
--
--   * Welcome: queued when the user's premium_access row is created, which is
--     the moment the free days start. Sent once, within ~10 minutes; dropped
--     if it could not go out within 48 hours.
--   * Reminder: 2 days before free Premium ends for 7-day users (day 5), 1 day
--     before for 3-day users. Only between 9:00 and 21:00 New York time, at
--     most once per end date (a friend's invite moves the end date, and the
--     user is reminded again before the new one). Users with a recent
--     RevenueCat purchase are skipped.
--
-- Emails go through the lifecycle-email edge function (Resend). Until its
-- RESEND_API_KEY secret is set, emails stay queued and expire unsent; the
-- push and the Notifications item work regardless.
--
-- The queue tables are server-only: no client can read or write them.

create table if not exists public.lifecycle_emails (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  kind text not null check (kind in ('welcome', 'premium_reminder')),
  dedupe_key text not null unique,
  status text not null default 'queued'
    check (status in ('queued', 'processing', 'sent', 'skipped', 'failed')),
  attempts integer not null default 0,
  send_after timestamptz not null default now(),
  expires_at timestamptz not null,
  claimed_at timestamptz,
  sent_at timestamptz,
  error text,
  created_at timestamptz not null default now()
);

create index if not exists lifecycle_emails_pending_idx
  on public.lifecycle_emails (send_after) where status = 'queued';
create index if not exists lifecycle_emails_user_idx
  on public.lifecycle_emails (user_id);

comment on table public.lifecycle_emails is
  'Welcome and Premium-reminder emails waiting for the lifecycle-email function. Server-only.';

create table if not exists public.premium_reminders (
  user_id uuid not null references public.profiles(id) on delete cascade,
  premium_until timestamptz not null,
  created_at timestamptz not null default now(),
  primary key (user_id, premium_until)
);

comment on table public.premium_reminders is
  'One row per reminder sent before a free-Premium end date. Server-only.';

alter table public.lifecycle_emails enable row level security;
alter table public.premium_reminders enable row level security;
revoke all on public.lifecycle_emails, public.premium_reminders from anon, authenticated;

-- Welcome email when the free days start.
create or replace function public.queue_welcome_email()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.lifecycle_emails (user_id, kind, dedupe_key, send_after, expires_at)
  values (new.user_id, 'welcome', 'welcome:' || new.user_id,
          now() + interval '2 minutes', now() + interval '48 hours')
  on conflict (dedupe_key) do nothing;
  return new;
end;
$$;

revoke all on function public.queue_welcome_email() from public, anon, authenticated;

drop trigger if exists queue_welcome_email_on_premium_access on public.premium_access;
create trigger queue_welcome_email_on_premium_access
after insert on public.premium_access
for each row execute function public.queue_welcome_email();

-- The social push trigger must not turn the reminder item into
-- "GymFeed sent you a new notification": queue_premium_reminders() queues its
-- own push. Otherwise identical to the definition in production.
create or replace function public.enqueue_social_push()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare actor_name text; push_body text; push_image text := '';
begin
  if new.type = 'premium_reminder' then
    return new;
  end if;
  select coalesce(nullif(display_name,''),nullif(username,''),'Someone')
    into actor_name from public.profiles where id=new.actor_id;
  push_body := case new.type
    when 'follow' then 'started following you'
    when 'like' then 'flexed on your post'
    when 'comment' then 'commented on your post'
    when 'tag' then 'tagged you in a post'
    else 'sent you a new notification' end;
  if new.post_id is not null then
    select coalesce(nullif(video_thumbnail,''),nullif(legacy_photo_url,''),'')
      into push_image from public.posts where id=new.post_id;
  end if;
  insert into public.push_queue(sender_id,recipient_ids,title,body,image_url,
    initial_page,parameter_data,source_kind,source_id)
  values(new.actor_id,array[new.recipient_id],coalesce(actor_name,'GymFeed'),
    push_body,coalesce(push_image,''),'Notifications','{}'::jsonb,
    'notification',new.id)
  on conflict do nothing;
  return new;
end;
$function$;

-- Finds users whose free Premium is about to end and reminds them once per
-- end date. Run by cron every 15 minutes. Returns how many were reminded.
-- p_now exists for tests; cron calls it without arguments.
create or replace function public.queue_premium_reminders(p_now timestamptz default now())
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  v_count integer := 0;
  v_days integer;
  v_invites integer;
  v_notification uuid;
  v_body text;
  v_hour integer := extract(hour from (p_now at time zone 'America/New_York'))::integer;
begin
  if v_hour < 9 or v_hour >= 21 then
    return 0;
  end if;

  for r in
    insert into public.premium_reminders (user_id, premium_until)
    select pa.user_id, pa.premium_until
      from public.premium_access pa
     where pa.premium_until > p_now + interval '1 hour'
       and pa.premium_until <= p_now + case when pa.trial_days >= 7
                                            then interval '2 days'
                                            else interval '1 day' end
       and not exists (
         select 1 from public.marketing_events me
          where me.user_id = pa.user_id
            and me.source = 'revenuecat'
            and me.event_name in ('subscription_started', 'subscription_renewed',
                                  'subscription_uncancelled', 'subscription_changed',
                                  'subscription_extended', 'one_time_purchase')
            and me.occurred_at > p_now - interval '40 days')
    on conflict do nothing
    returning user_id, premium_until
  loop
    v_days := greatest(1, ceil(extract(epoch from (r.premium_until - p_now)) / 86400)::integer);
    select count(*)::integer into v_invites
      from public.premium_referrals where inviter_id = r.user_id;

    insert into public.notifications (recipient_id, actor_id, type)
    values (r.user_id, null, 'premium_reminder')
    returning id into v_notification;

    v_body := v_days || case when v_days = 1 then ' day' else ' days' end
      || ' of Premium left. '
      || case when v_invites < 4
              then 'Invite a friend and you both get 7 more days.'
              else 'Keep your AI coach with GymFeed Pro.' end;

    if v_notification is not null then
      insert into public.push_queue (sender_id, recipient_ids, title, body,
        initial_page, parameter_data, source_kind, source_id)
      values (null, array[r.user_id], 'GymFeed', v_body, 'Notifications',
              '{}'::jsonb, 'premium_reminder', v_notification)
      on conflict do nothing;
    end if;

    insert into public.lifecycle_emails (user_id, kind, dedupe_key, send_after, expires_at)
    values (r.user_id, 'premium_reminder',
            'premium_reminder:' || r.user_id || ':' || floor(extract(epoch from r.premium_until))::bigint,
            now(), r.premium_until)
    on conflict (dedupe_key) do nothing;

    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.queue_premium_reminders(timestamptz) from public, anon, authenticated;

-- Marks queued emails that are no longer worth sending.
create or replace function public.expire_lifecycle_emails()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  update public.lifecycle_emails
     set status = 'skipped', error = 'expired'
   where status = 'queued' and expires_at <= now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Claims a batch for the lifecycle-email function, with everything the
-- templates need. Test and demo addresses are skipped here.
create or replace function public.claim_lifecycle_emails(p_batch_size integer default 20)
returns table (
  id uuid,
  kind text,
  email text,
  display_name text,
  username text,
  founding_number integer,
  trial_days integer,
  premium_until timestamptz,
  invites_used integer
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.expire_lifecycle_emails();

  -- A worker that died mid-batch leaves rows in processing; retry them.
  update public.lifecycle_emails e
     set status = 'queued'
   where e.status = 'processing' and e.claimed_at < now() - interval '15 minutes';

  update public.lifecycle_emails e
     set status = 'skipped', error = 'test or missing address'
   where e.status = 'queued'
     and e.send_after <= now()
     and not exists (
       select 1 from auth.users u
        where u.id = e.user_id
          and u.email is not null
          and not public.founding_is_test_email(u.email));

  return query
  with picked as (
    select e.id
      from public.lifecycle_emails e
     where e.status = 'queued' and e.send_after <= now()
     order by e.send_after
     for update skip locked
     limit greatest(1, least(coalesce(p_batch_size, 20), 100))
  ),
  claimed as (
    update public.lifecycle_emails e
       set status = 'processing', attempts = e.attempts + 1, claimed_at = now()
      from picked
     where e.id = picked.id
    returning e.id, e.kind, e.user_id
  )
  select c.id, c.kind, u.email::text, p.display_name, p.username,
         fm.founding_number, pa.trial_days, pa.premium_until,
         (select count(*)::integer from public.premium_referrals r where r.inviter_id = c.user_id)
    from claimed c
    left join auth.users u on u.id = c.user_id
    left join public.profiles p on p.id = c.user_id
    left join public.founding_members fm on fm.user_id = c.user_id
    left join public.premium_access pa on pa.user_id = c.user_id;
end;
$$;

-- Records the outcome. 'retry' backs off 10 minutes per attempt and gives up
-- after 5 attempts.
create or replace function public.finish_lifecycle_email(p_id uuid, p_status text, p_error text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_status not in ('sent', 'skipped', 'failed', 'retry') then
    raise exception 'invalid status %', p_status;
  end if;
  update public.lifecycle_emails e
     set status = case
                    when p_status <> 'retry' then p_status
                    when e.attempts >= 5 then 'failed'
                    else 'queued'
                  end,
         send_after = case when p_status = 'retry'
                           then now() + make_interval(mins => 10 * e.attempts)
                           else e.send_after end,
         sent_at = case when p_status = 'sent' then now() else e.sent_at end,
         error = left(p_error, 500)
   where e.id = p_id and e.status = 'processing';
end;
$$;

revoke all on function public.expire_lifecycle_emails() from public, anon, authenticated;
revoke all on function public.claim_lifecycle_emails(integer) from public, anon, authenticated;
revoke all on function public.finish_lifecycle_email(uuid, text, text) from public, anon, authenticated;
grant execute on function public.expire_lifecycle_emails() to service_role;
grant execute on function public.claim_lifecycle_emails(integer) to service_role;
grant execute on function public.finish_lifecycle_email(uuid, text, text) to service_role;

select cron.unschedule(jobid) from cron.job
 where jobname in ('gymfeed-premium-reminders', 'gymfeed-lifecycle-email');

select cron.schedule(
  'gymfeed-premium-reminders',
  '*/15 * * * *',
  $$ select public.queue_premium_reminders(); $$
);

select cron.schedule(
  'gymfeed-lifecycle-email',
  '*/5 * * * *',
  $$
    select net.http_post(
      url := 'https://bzinwojowkxavfzilvat.supabase.co/functions/v1/lifecycle-email',
      headers := '{"Content-Type":"application/json"}'::jsonb,
      body := '{"source":"cron"}'::jsonb,
      timeout_milliseconds := 30000
    );
  $$
);
