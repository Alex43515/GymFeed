-- 0008_reels_page.sql
-- Feeds the Reels player: video posts only, newest first, OFFSET-paginated in
-- small pages (default 6) so the client can preload a few and fetch more as the
-- user scrolls — Instagram-style. Same column shape as feed_page(), so
-- PostsRecord.fromFeedRow parses the rows unchanged.

create or replace function reels_page(
  p_offset int default 0,
  p_limit  int default 6
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
  select p.id, p.created_at, p.caption,
         coalesce(ma_photo.storage_path, p.legacy_photo_url),
         coalesce(ma_video.thumbnail_url, p.legacy_video_url),
         p.video_thumbnail,
         coalesce(ma_photo.blurhash, ma_video.blurhash, ''),
         p.food_post, p.like_count, p.comment_count,
         exists (select 1 from post_likes pl
                 where pl.post_id = p.id and pl.user_id = auth.uid()),
         pr.id, pr.username, pr.display_name, pr.photo_url
    from posts p
    join profiles pr on pr.id = p.user_id
    left join media_assets ma_photo on ma_photo.id = p.photo_asset_id
    left join media_assets ma_video on ma_video.id = p.video_asset_id
   where not p.deleted
     and coalesce(p.legacy_video_url, '') <> ''   -- video posts only
     and not exists (select 1 from user_blocks b
                     where (b.blocker_id = auth.uid() and b.blocked_id = p.user_id)
                        or (b.blocker_id = p.user_id and b.blocked_id = auth.uid()))
   order by p.created_at desc
   limit least(p_limit, 20)
   offset greatest(p_offset, 0);
$$;
