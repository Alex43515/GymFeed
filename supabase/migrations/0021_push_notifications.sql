-- Restore production push delivery after the Firebase -> Supabase migration.
-- Social rows remain authoritative; clients cannot choose arbitrary recipients.

create extension if not exists pg_cron;
create extension if not exists pg_net;

create or replace function public.register_fcm_token(
  p_token text,
  p_device_type text default ''
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'authentication required';
  end if;
  if p_token is null or length(trim(p_token)) < 20 or length(p_token) > 4096 then
    raise exception 'invalid FCM token';
  end if;

  -- A device token belongs to exactly one signed-in account at a time.
  delete from public.fcm_tokens where token = trim(p_token);
  insert into public.fcm_tokens (user_id, token, device_type)
  values (caller, trim(p_token), left(coalesce(p_device_type, ''), 20));
end;
$$;

revoke all on function public.register_fcm_token(text, text) from public, anon;
grant execute on function public.register_fcm_token(text, text) to authenticated;

create or replace function public.claim_push_notifications(p_batch_size int default 25)
returns setof public.push_queue
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  with candidates as (
    select q.id
      from public.push_queue q
     where q.status = 'queued'
     order by q.created_at
     for update skip locked
     limit greatest(1, least(coalesce(p_batch_size, 25), 100))
  )
  update public.push_queue q
     set status = 'processing', error = null
    from candidates c
   where q.id = c.id
  returning q.*;
end;
$$;

revoke all on function public.claim_push_notifications(int) from public, anon, authenticated;
grant execute on function public.claim_push_notifications(int) to service_role;

drop policy if exists "notify as actor" on public.notifications;
drop policy if exists "enqueue push as self" on public.push_queue;

create or replace function public.enqueue_social_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  actor_name text;
  push_body text;
  push_image text := '';
begin
  select coalesce(nullif(display_name, ''), nullif(username, ''), 'Someone')
    into actor_name
    from public.profiles
   where id = new.actor_id;

  push_body := case new.type
    when 'follow' then 'started following you'
    when 'like' then 'flexed on your post'
    when 'comment' then 'commented on your post'
    else 'sent you a new notification'
  end;

  if new.post_id is not null then
    select coalesce(nullif(video_thumbnail, ''), nullif(legacy_photo_url, ''), '')
      into push_image
      from public.posts
     where id = new.post_id;
  end if;

  insert into public.push_queue (
    sender_id,
    recipient_ids,
    title,
    body,
    image_url,
    initial_page,
    parameter_data
  ) values (
    new.actor_id,
    array[new.recipient_id],
    coalesce(actor_name, 'GymFeed'),
    push_body,
    coalesce(push_image, ''),
    'Notifications',
    '{}'::jsonb
  );
  return new;
end;
$$;

drop trigger if exists enqueue_social_push_on_notification on public.notifications;
create trigger enqueue_social_push_on_notification
after insert on public.notifications
for each row execute function public.enqueue_social_push();

create or replace function public.enqueue_chat_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  recipients uuid[];
  actor_name text;
  preview text;
begin
  if new.text like '__gymfeed_reaction__:%'
     or new.text like '__gymfeed_read__:%' then
    return new;
  end if;

  select array_agg(user_id)
    into recipients
    from public.chat_members
   where chat_id = new.chat_id
     and user_id <> new.user_id;
  if recipients is null or cardinality(recipients) = 0 then return new; end if;

  select coalesce(nullif(display_name, ''), nullif(username, ''), 'New message')
    into actor_name
    from public.profiles
   where id = new.user_id;
  preview := case
    when nullif(trim(new.text), '') is not null then left(new.text, 140)
    when nullif(new.video_url, '') is not null then 'Sent a video'
    when nullif(new.image_url, '') is not null then 'Sent a photo'
    else 'Sent you a message'
  end;

  insert into public.push_queue (
    sender_id, recipient_ids, title, body, initial_page, parameter_data
  ) values (
    new.user_id,
    recipients,
    coalesce(actor_name, 'New message'),
    preview,
    'Messages',
    jsonb_build_object('chat_id', new.chat_id)
  );
  return new;
end;
$$;

drop trigger if exists enqueue_chat_push_on_message on public.chat_messages;
create trigger enqueue_chat_push_on_message
after insert on public.chat_messages
for each row execute function public.enqueue_chat_push();

create or replace function public.wake_push_worker()
returns trigger
language plpgsql
security definer
set search_path = public, net
as $$
begin
  perform net.http_post(
    url := 'https://bzinwojowkxavfzilvat.supabase.co/functions/v1/push-worker',
    headers := '{"Content-Type":"application/json"}'::jsonb,
    body := jsonb_build_object('source', 'database', 'queue_id', new.id),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;

drop trigger if exists wake_push_worker_on_queue on public.push_queue;
create trigger wake_push_worker_on_queue
after insert on public.push_queue
for each row execute function public.wake_push_worker();

select cron.unschedule(jobid)
  from cron.job
 where jobname = 'gymfeed-push-worker';

select cron.schedule(
  'gymfeed-push-worker',
  '* * * * *',
  $$
    select net.http_post(
      url := 'https://bzinwojowkxavfzilvat.supabase.co/functions/v1/push-worker',
      headers := '{"Content-Type":"application/json"}'::jsonb,
      body := '{"source":"cron"}'::jsonb,
      timeout_milliseconds := 10000
    );
  $$
);

comment on function public.register_fcm_token(text, text) is
  'Atomically associates an FCM device token with the authenticated user.';
comment on function public.claim_push_notifications(int) is
  'Claims queued notifications with SKIP LOCKED for the service-role push worker.';
