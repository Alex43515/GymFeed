-- Include interaction permissions in the hydrated Home feed so the client can
-- show or disable like/comment controls without one query per post.

drop function if exists public.feed_page(integer, integer);

create function public.feed_page(
  p_offset integer default 0,
  p_limit  integer default 25
)
returns table (
  post_id uuid,
  created_at timestamptz,
  caption text,
  photo_url text,
  video_url text,
  video_thumbnail text,
  blurhash text,
  food_post boolean,
  allow_comments boolean,
  allow_likes boolean,
  like_count integer,
  comment_count integer,
  liked_by_me boolean,
  author_id uuid,
  author_username text,
  author_display_name text,
  author_photo_url text
)
language sql
security invoker
stable
set search_path = public
as $$
  with me as (select auth.uid() as uid),
       my_follows as (
         select f.followee_id
           from public.follows f, me
          where f.follower_id = me.uid
       ),
       has_follows as (select exists (select 1 from my_follows) as v)
  select p.id, p.created_at, p.caption,
         coalesce(ma_photo.storage_path, p.legacy_photo_url),
         coalesce(ma_video.thumbnail_url, p.legacy_video_url),
         p.video_thumbnail,
         coalesce(ma_photo.blurhash, ma_video.blurhash, ''),
         p.food_post, p.allow_comments, p.allow_likes,
         p.like_count, p.comment_count,
         exists (select 1 from public.post_likes pl
                 where pl.post_id = p.id and pl.user_id = (select uid from me)),
         pr.id, pr.username, pr.display_name, pr.photo_url
    from public.posts p
    join public.profiles pr on pr.id = p.user_id
    left join public.media_assets ma_photo on ma_photo.id = p.photo_asset_id
    left join public.media_assets ma_video on ma_video.id = p.video_asset_id
   where not p.deleted
     and (
       not (select v from has_follows)
       or p.user_id = (select uid from me)
       or p.user_id in (select followee_id from my_follows)
     )
     and not exists (
       select 1
         from public.user_blocks b
        where (b.blocker_id = (select uid from me) and b.blocked_id = p.user_id)
           or (b.blocker_id = p.user_id and b.blocked_id = (select uid from me))
     )
   order by (
       (p.like_count * 2 + p.comment_count * 3)::float8
       - (extract(epoch from (now() - p.created_at)) / 3600.0) * 0.8
     ) desc,
     p.created_at desc
   limit least(p_limit, 50)
   offset greatest(p_offset, 0);
$$;

revoke execute on function public.feed_page(integer, integer) from public, anon;
grant execute on function public.feed_page(integer, integer) to authenticated;
