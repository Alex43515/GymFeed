-- Founding Members launch: remove the 5 old demo profiles and their 76 posts.
--
-- Run manually, once, after the backup in schema backup_demo_20261107 exists
-- (migration backup_demo_profiles_20261107, applied 2026-11-07).
--
-- Deleting the auth user cascades to profiles -> posts, likes, comments,
-- notifications, chat membership, follows, etc. (all FKs are ON DELETE CASCADE).
-- Only accounts on the gymfeed.test domain can match, as a safety net.

begin;

do $$
declare
  backup_rows int;
begin
  select count(*) into backup_rows from backup_demo_20261107.posts__user_id;
  if backup_rows <> 76 then
    raise exception 'Backup has % posts, expected 76. Aborting.', backup_rows;
  end if;
end $$;

delete from auth.users u
using public.profiles p
where p.id = u.id
  and p.username in ('alexs', 'tumbashmisha', 'lazalaza', 'boris92', 'sophygreen')
  and u.email like '%@gymfeed.test';

-- Expect: 0 profiles and 0 posts left for these usernames.
select
  (select count(*) from public.profiles
     where username in ('alexs','tumbashmisha','lazalaza','boris92','sophygreen')) as profiles_left,
  (select count(*) from public.posts
     where id in (select id from backup_demo_20261107.demo_post_ids)) as posts_left;

commit;

-- Restore (if ever needed): insert back from backup_demo_20261107, starting with
-- auth_users, auth_identities, profiles__id, profile_private__id, posts__user_id,
-- then the remaining tables.
