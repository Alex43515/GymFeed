-- Populate the notifications table from the authoritative social tables.
-- This keeps notifications working for every client (including older builds)
-- without asking mobile code to perform a second, failure-prone insert.

create or replace function public.create_social_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user uuid;
  notification_type text;
begin
  if tg_table_name = 'follows' then
    target_user := new.followee_id;
    notification_type := 'follow';

    if target_user <> new.follower_id then
      insert into public.notifications (recipient_id, actor_id, type)
      values (target_user, new.follower_id, notification_type);
    end if;

  elsif tg_table_name = 'post_likes' then
    select p.user_id into target_user
      from public.posts p
     where p.id = new.post_id;
    notification_type := 'like';

    if target_user is not null and target_user <> new.user_id then
      insert into public.notifications (recipient_id, actor_id, type, post_id)
      values (target_user, new.user_id, notification_type, new.post_id);
    end if;

  elsif tg_table_name = 'comments' then
    select p.user_id into target_user
      from public.posts p
     where p.id = new.post_id;
    notification_type := 'comment';

    if target_user is not null and target_user <> new.user_id then
      insert into public.notifications
        (recipient_id, actor_id, type, post_id, comment_id)
      values
        (target_user, new.user_id, notification_type, new.post_id, new.id);
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists notify_new_follow on public.follows;
create trigger notify_new_follow
after insert on public.follows
for each row execute function public.create_social_notification();

drop trigger if exists notify_post_like on public.post_likes;
create trigger notify_post_like
after insert on public.post_likes
for each row execute function public.create_social_notification();

drop trigger if exists notify_post_comment on public.comments;
create trigger notify_post_comment
after insert on public.comments
for each row execute function public.create_social_notification();

revoke execute on function public.create_social_notification() from public;
revoke execute on function public.create_social_notification() from anon;
revoke execute on function public.create_social_notification() from authenticated;

comment on function public.create_social_notification() is
  'Creates recipient-scoped follow, like and comment notifications.';
