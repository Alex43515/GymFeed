-- A social action has one durable source row.  Use that source identity rather
-- than transaction ids so legacy client inserts, retries, and DB triggers can
-- never create two notifications or two push jobs for one action.

update public.notifications set type = case lower(trim(type))
  when 'post_like' then 'like'
  when 'post-like' then 'like'
  when 'new_follow' then 'follow'
  when 'new-follower' then 'follow'
  when 'post_comment' then 'comment'
  when 'post-comment' then 'comment'
  else lower(trim(type)) end;

with ranked as (
  select id, row_number() over (
    partition by type, recipient_id, actor_id,
      coalesce(post_id, '00000000-0000-0000-0000-000000000000'::uuid),
      coalesce(comment_id, '00000000-0000-0000-0000-000000000000'::uuid)
    order by created_at desc, id desc) as n
  from public.notifications
  where type in ('like','follow','comment','tag')
)
delete from public.notifications n using ranked r
 where n.id = r.id and r.n > 1;

-- Generated legacy clients inserted a second comment notification without the
-- newly-created comment id.  Prefer the trigger-created, source-linked row.
delete from public.notifications legacy
using public.notifications authoritative
where legacy.type='comment'
  and legacy.comment_id is null
  and authoritative.type='comment'
  and authoritative.comment_id is not null
  and authoritative.recipient_id=legacy.recipient_id
  and authoritative.actor_id=legacy.actor_id
  and authoritative.post_id=legacy.post_id
  and abs(extract(epoch from
      (authoritative.created_at-legacy.created_at))) < 120;

drop index if exists public.notifications_like_event_unique;
drop index if exists public.notifications_follow_event_unique;
drop index if exists public.notifications_comment_event_unique;

create unique index if not exists notifications_like_source_unique
  on public.notifications(recipient_id, actor_id, post_id)
  where type = 'like' and actor_id is not null and post_id is not null;
create unique index if not exists notifications_follow_source_unique
  on public.notifications(recipient_id, actor_id)
  where type = 'follow' and actor_id is not null;
create unique index if not exists notifications_comment_source_unique
  on public.notifications(recipient_id, actor_id, comment_id)
  where type = 'comment' and actor_id is not null and comment_id is not null;
create unique index if not exists notifications_tag_source_unique
  on public.notifications(recipient_id, actor_id, post_id)
  where type = 'tag' and actor_id is not null and post_id is not null;

-- Client code from older APKs can still attempt to insert the same row after
-- the authoritative database trigger has done so.  Suppress that insert before
-- it reaches the durable unique indexes instead of returning a unique-violation
-- error to the old client.
create or replace function public.suppress_duplicate_social_notification()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  new.type := case lower(trim(new.type))
    when 'post_like' then 'like'
    when 'post-like' then 'like'
    when 'post_comment' then 'comment'
    when 'post-comment' then 'comment'
    when 'new_follow' then 'follow'
    when 'new-follower' then 'follow'
    else lower(trim(new.type)) end;

  if new.type = 'like' and exists (
    select 1 from public.notifications n where n.type='like'
      and n.recipient_id=new.recipient_id and n.actor_id=new.actor_id
      and n.post_id=new.post_id
  ) then return null; end if;
  if new.type = 'follow' and exists (
    select 1 from public.notifications n where n.type='follow'
      and n.recipient_id=new.recipient_id and n.actor_id=new.actor_id
  ) then return null; end if;
  if new.type = 'comment' and exists (
    select 1 from public.notifications n where n.type='comment'
      and n.recipient_id=new.recipient_id and n.actor_id=new.actor_id
      and (
        (new.comment_id is not null and n.comment_id=new.comment_id)
        or (new.comment_id is null and n.post_id=new.post_id
            and n.created_at > now() - interval '2 minutes')
      )
  ) then return null; end if;
  if new.type = 'tag' and exists (
    select 1 from public.notifications n where n.type='tag'
      and n.recipient_id=new.recipient_id and n.actor_id=new.actor_id
      and n.post_id=new.post_id
  ) then return null; end if;
  return new;
end;
$$;

drop trigger if exists suppress_duplicate_social_notification_insert
  on public.notifications;
create trigger suppress_duplicate_social_notification_insert
before insert on public.notifications
for each row execute function public.suppress_duplicate_social_notification();

create or replace function public.create_social_notification()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare target_user uuid;
begin
  if tg_table_name = 'follows' then
    target_user := new.followee_id;
    if target_user <> new.follower_id then
      insert into public.notifications(recipient_id, actor_id, type)
      values(target_user, new.follower_id, 'follow') on conflict do nothing;
    end if;
  elsif tg_table_name = 'post_likes' then
    select user_id into target_user from public.posts where id = new.post_id;
    if target_user is not null and target_user <> new.user_id then
      insert into public.notifications(recipient_id, actor_id, type, post_id)
      values(target_user, new.user_id, 'like', new.post_id) on conflict do nothing;
    end if;
  elsif tg_table_name = 'comments' then
    select user_id into target_user from public.posts where id = new.post_id;
    if target_user is not null and target_user <> new.user_id then
      insert into public.notifications(recipient_id, actor_id, type, post_id, comment_id)
      values(target_user, new.user_id, 'comment', new.post_id, new.id)
      on conflict do nothing;
    end if;
  elsif tg_table_name = 'post_tags' then
    select user_id into target_user from public.posts where id = new.post_id;
    if new.user_id <> target_user then
      insert into public.notifications(recipient_id, actor_id, type, post_id)
      values(new.user_id, target_user, 'tag', new.post_id) on conflict do nothing;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists post_tags_create_notification on public.post_tags;
create trigger post_tags_create_notification after insert on public.post_tags
for each row execute function public.create_social_notification();

create or replace function public.remove_social_notification_with_source()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare post_owner uuid;
begin
  if tg_table_name = 'follows' then
    delete from public.notifications where type='follow'
      and recipient_id=old.followee_id and actor_id=old.follower_id;
  elsif tg_table_name = 'post_likes' then
    select user_id into post_owner from public.posts where id=old.post_id;
    delete from public.notifications where type='like'
      and recipient_id=post_owner and actor_id=old.user_id and post_id=old.post_id;
  elsif tg_table_name = 'comments' then
    delete from public.notifications where type='comment' and comment_id=old.id;
  elsif tg_table_name = 'post_tags' then
    delete from public.notifications where type='tag'
      and recipient_id=old.user_id and post_id=old.post_id;
  end if;
  return old;
end;
$$;

drop trigger if exists follows_remove_notification on public.follows;
create trigger follows_remove_notification after delete on public.follows
for each row execute function public.remove_social_notification_with_source();
drop trigger if exists post_likes_remove_notification on public.post_likes;
create trigger post_likes_remove_notification after delete on public.post_likes
for each row execute function public.remove_social_notification_with_source();
drop trigger if exists comments_remove_notification on public.comments;
create trigger comments_remove_notification after delete on public.comments
for each row execute function public.remove_social_notification_with_source();
drop trigger if exists post_tags_remove_notification on public.post_tags;
create trigger post_tags_remove_notification after delete on public.post_tags
for each row execute function public.remove_social_notification_with_source();

alter table public.push_queue add column if not exists source_kind text;
alter table public.push_queue add column if not exists source_id uuid;

with ranked as (
  select id, row_number() over(partition by source_kind, source_id
    order by created_at desc, id desc) n
  from public.push_queue where source_kind is not null and source_id is not null
)
delete from public.push_queue q using ranked r where q.id=r.id and r.n>1;

create unique index if not exists push_queue_source_unique
  on public.push_queue(source_kind, source_id)
  where source_kind is not null and source_id is not null;

create or replace function public.enqueue_social_push()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare actor_name text; push_body text; push_image text := '';
begin
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
$$;

create or replace function public.enqueue_chat_push()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare recipients uuid[]; actor_name text; preview text;
begin
  if new.text like '__gymfeed_reaction__:%' or new.text like '__gymfeed_read__:%' then return new; end if;
  select array_agg(user_id) into recipients from public.chat_members
   where chat_id=new.chat_id and user_id<>new.user_id;
  if recipients is null or cardinality(recipients)=0 then return new; end if;
  select coalesce(nullif(display_name,''),nullif(username,''),'New message')
    into actor_name from public.profiles where id=new.user_id;
  preview := case
    when nullif(trim(new.text),'') is not null then left(new.text,140)
    when nullif(new.video_url,'') is not null then 'Sent a video'
    when nullif(new.image_url,'') is not null then 'Sent a photo'
    else 'Sent you a message' end;
  insert into public.push_queue(sender_id,recipient_ids,title,body,initial_page,
    parameter_data,source_kind,source_id)
  values(new.user_id,recipients,coalesce(actor_name,'New message'),preview,
    'Messages',jsonb_build_object('chat_id',new.chat_id),'chat_message',new.id)
  on conflict do nothing;
  return new;
end;
$$;

-- One physical device token must not appear twice, otherwise one push is sent
-- once per duplicate row even if the queue is perfectly deduplicated.
delete from public.fcm_tokens a using public.fcm_tokens b
 where a.token=b.token and a.created_at < b.created_at;
create unique index if not exists fcm_tokens_token_unique on public.fcm_tokens(token);
