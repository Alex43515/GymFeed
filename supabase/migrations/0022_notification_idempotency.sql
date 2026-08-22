-- Prevent duplicate in-app and push notifications for one social action.
--
-- The initial schema installed legacy *_notify triggers. Migration 0016 then
-- installed the authoritative create_social_notification() triggers without
-- removing those legacy triggers, so a single insert could create two rows and
-- therefore enqueue two pushes.

-- Remove only the superseded notification triggers. Count-maintenance triggers
-- on these tables are intentionally left in place.
drop trigger if exists post_likes_notify on public.post_likes;
drop trigger if exists follows_notify on public.follows;
drop trigger if exists comments_notify on public.comments;

-- Normalize legacy names so clients see one stable notification vocabulary.
update public.notifications
   set type = 'like'
 where lower(trim(type)) in ('like', 'post_like', 'post-like');

update public.notifications
   set type = 'follow'
 where lower(trim(type)) in ('follow', 'new_follow', 'new-follower');

update public.notifications
   set type = 'comment'
 where lower(trim(type)) in ('comment', 'post_comment', 'post-comment');

-- Remove existing duplicates while keeping the newest row. This also removes
-- the extra notification rows shown by older clients.
with ranked_social_notifications as (
  select id,
         row_number() over (
           partition by type, recipient_id, actor_id, post_id, comment_id
           order by created_at desc, id desc
         ) as duplicate_number
    from public.notifications
   where type in ('like', 'follow', 'comment')
)
delete from public.notifications n
using ranked_social_notifications ranked
where n.id = ranked.id
  and ranked.duplicate_number > 1;

-- Each notification created by multiple triggers for the same source insert is
-- in the same PostgreSQL transaction. Keeping that transaction id lets a later
-- unlike/re-like or unfollow/refollow produce a fresh notification, while the
-- duplicate insert from the same event is ignored.
alter table public.notifications
  add column if not exists source_transaction_id bigint;

update public.notifications
   set source_transaction_id = 0
 where source_transaction_id is null;

alter table public.notifications
  alter column source_transaction_id set default txid_current(),
  alter column source_transaction_id set not null;

create unique index if not exists notifications_like_event_unique
  on public.notifications
    (recipient_id, actor_id, post_id, source_transaction_id)
  where type = 'like'
    and actor_id is not null
    and post_id is not null;

create unique index if not exists notifications_follow_event_unique
  on public.notifications
    (recipient_id, actor_id, source_transaction_id)
  where type = 'follow'
    and actor_id is not null;

create unique index if not exists notifications_comment_event_unique
  on public.notifications
    (recipient_id, actor_id, comment_id, source_transaction_id)
  where type = 'comment'
    and actor_id is not null
    and comment_id is not null;

-- A BEFORE trigger makes the protection compatible with a replayed legacy
-- migration whose function uses a plain INSERT (rather than ON CONFLICT).
create or replace function public.suppress_duplicate_social_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  new.type := case lower(trim(new.type))
    when 'post_like' then 'like'
    when 'post-like' then 'like'
    when 'post_comment' then 'comment'
    when 'post-comment' then 'comment'
    when 'new_follow' then 'follow'
    when 'new-follower' then 'follow'
    else lower(trim(new.type))
  end;

  if new.source_transaction_id is null then
    new.source_transaction_id := txid_current();
  end if;

  if new.type = 'like' and exists (
    select 1
      from public.notifications n
     where n.type = 'like'
       and n.recipient_id = new.recipient_id
       and n.actor_id = new.actor_id
       and n.post_id = new.post_id
       and n.source_transaction_id = new.source_transaction_id
  ) then
    return null;
  end if;

  if new.type = 'follow' and exists (
    select 1
      from public.notifications n
     where n.type = 'follow'
       and n.recipient_id = new.recipient_id
       and n.actor_id = new.actor_id
       and n.source_transaction_id = new.source_transaction_id
  ) then
    return null;
  end if;

  if new.type = 'comment' and exists (
    select 1
      from public.notifications n
     where n.type = 'comment'
       and n.recipient_id = new.recipient_id
       and n.actor_id = new.actor_id
       and n.comment_id = new.comment_id
       and n.source_transaction_id = new.source_transaction_id
  ) then
    return null;
  end if;

  return new;
end;
$$;

drop trigger if exists suppress_duplicate_social_notification_insert
  on public.notifications;
create trigger suppress_duplicate_social_notification_insert
before insert on public.notifications
for each row execute function public.suppress_duplicate_social_notification();

revoke execute on function public.suppress_duplicate_social_notification()
  from public, anon, authenticated;

-- Keep the authoritative trigger function idempotent as an additional guard.
create or replace function public.create_social_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user uuid;
begin
  if tg_table_name = 'follows' then
    target_user := new.followee_id;

    if target_user <> new.follower_id then
      insert into public.notifications (recipient_id, actor_id, type)
      values (target_user, new.follower_id, 'follow')
      on conflict do nothing;
    end if;

  elsif tg_table_name = 'post_likes' then
    select p.user_id into target_user
      from public.posts p
     where p.id = new.post_id;

    if target_user is not null and target_user <> new.user_id then
      insert into public.notifications (recipient_id, actor_id, type, post_id)
      values (target_user, new.user_id, 'like', new.post_id)
      on conflict do nothing;
    end if;

  elsif tg_table_name = 'comments' then
    select p.user_id into target_user
      from public.posts p
     where p.id = new.post_id;

    if target_user is not null and target_user <> new.user_id then
      insert into public.notifications
        (recipient_id, actor_id, type, post_id, comment_id)
      values
        (target_user, new.user_id, 'comment', new.post_id, new.id)
      on conflict do nothing;
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function public.create_social_notification() from public;
revoke execute on function public.create_social_notification() from anon;
revoke execute on function public.create_social_notification() from authenticated;

comment on function public.suppress_duplicate_social_notification() is
  'Canonicalizes social notification types and suppresses duplicate inserts from the same source transaction.';

