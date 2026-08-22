-- 0007_feed_relevance.sql
-- Replaces the recency-only feed_page() with a relevance-ranked, follow-aware
-- feed that mimics Instagram/Facebook home ranking:
--
--   * Base set — if you follow anyone, you see your own posts + posts from the
--     people you follow. If you follow NOBODY, you see everyone's posts (so a
--     brand-new account isn't staring at an empty feed).
--   * Ranking — a blended score of engagement (likes/comments) minus a gentle
--     recency decay, so fresh content stays near the top but a highly-engaged
--     post can out-rank a brand-new one. created_at breaks ties.
--   * Pagination — OFFSET based (relevance ordering isn't keyset-friendly), so
--     the client asks for p_offset 0, 25, 50, … Page size defaults to 25.
--
-- Returns the same columns as before, so PostsRecord.fromFeedRow is unchanged.

create or replace function feed_page(
  p_offset int default 0,
  p_limit  int default 25
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
  like_count int,
  comment_count int,
  liked_by_me boolean,
  author_id uuid,
  author_username text,
  author_display_name text,
  author_photo_url text
)
language sql
security invoker
stable
as $$
  with me as (select auth.uid() as uid),
       my_follows as (
         select f.followee_id
           from follows f, me
          where f.follower_id = me.uid
       ),
       has_follows as (select exists (select 1 from my_follows) as v)
  select p.id, p.created_at, p.caption,
         coalesce(ma_photo.storage_path, p.legacy_photo_url),
         coalesce(ma_video.thumbnail_url, p.legacy_video_url),
         p.video_thumbnail,
         coalesce(ma_photo.blurhash, ma_video.blurhash, ''),
         p.food_post, p.like_count, p.comment_count,
         exists (select 1 from post_likes pl
                 where pl.post_id = p.id and pl.user_id = (select uid from me)),
         pr.id, pr.username, pr.display_name, pr.photo_url
    from posts p
    join profiles pr on pr.id = p.user_id
    left join media_assets ma_photo on ma_photo.id = p.photo_asset_id
    left join media_assets ma_video on ma_video.id = p.video_asset_id
   where not p.deleted
     and (
       -- no follows yet -> show all content
       not (select v from has_follows)
       or p.user_id = (select uid from me)
       or p.user_id in (select followee_id from my_follows)
     )
     and not exists (select 1 from user_blocks b
                     where (b.blocker_id = (select uid from me) and b.blocked_id = p.user_id)
                        or (b.blocker_id = p.user_id and b.blocked_id = (select uid from me)))
   order by (
       (p.like_count * 2 + p.comment_count * 3)::float8
       - (extract(epoch from (now() - p.created_at)) / 3600.0) * 0.8
     ) desc,
     p.created_at desc
   limit least(p_limit, 50)
   offset greatest(p_offset, 0);
$$;
