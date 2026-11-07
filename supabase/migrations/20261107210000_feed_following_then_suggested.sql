-- Home feed like Instagram: your own posts and posts from people you follow
-- come first; once those run out, posts from everyone else follow as
-- "Suggested for you". The feed is never empty.
--
-- Each row now carries feed_section ('following' | 'suggested') so the app can
-- show "You're all caught up" / "Suggested for you" between the two parts.
-- Older app builds ignore the extra column and simply see more posts after the
-- followed ones (previously the feed ended there).
--
-- Adding a column changes the return type, so the function is recreated.

drop function if exists public.feed_page(integer, integer);

create function public.feed_page(p_offset integer default 0, p_limit integer default 25)
returns table(
  post_id uuid, created_at timestamptz, caption text, photo_url text,
  video_url text, video_thumbnail text, blurhash text, food_post boolean,
  allow_comments boolean, allow_likes boolean, location text,
  call_to_action_enabled boolean, call_to_action_text text,
  call_to_action_link text, food_title text, food_description text,
  recipe text, nutrition_facts text, cooking_time text, meal_type text,
  calories integer, protein integer, fats text, carbs text,
  tagged_user_ids uuid[], like_count integer, comment_count integer,
  liked_by_me boolean, author_id uuid, author_username text,
  author_display_name text, author_photo_url text, feed_section text
)
language sql
stable
set search_path to 'public'
as $function$
  with me as (select auth.uid() as uid),
       my_follows as (
         select f.followee_id from public.follows f, me
          where f.follower_id = me.uid
       ),
       ranked as (
         select p.*,
                case
                  when p.user_id = (select uid from me)
                    or p.user_id in (select followee_id from my_follows)
                  then 0 else 1
                end as section_rank,
                ((p.like_count * 2 + p.comment_count * 3)::float8
                  - (extract(epoch from (now() - p.created_at)) / 3600.0) * 0.8)
                  as score
           from public.posts p
          where not p.deleted
            and not exists (
              select 1 from public.user_blocks b
               where (b.blocker_id = (select uid from me) and b.blocked_id = p.user_id)
                  or (b.blocker_id = p.user_id and b.blocked_id = (select uid from me))
            )
       )
  select p.id, p.created_at, p.caption,
         coalesce(ma_photo.storage_path, p.legacy_photo_url),
         coalesce(nullif(ma_video.playback_url, ''), p.legacy_video_url),
         coalesce(nullif(ma_video.thumbnail_url, ''), p.video_thumbnail),
         coalesce(ma_photo.blurhash, ma_video.blurhash, ''),
         p.food_post, p.allow_comments, p.allow_likes,
         p.location, p.call_to_action_enabled, p.call_to_action_text,
         p.call_to_action_link, p.food_title, p.food_description, p.recipe,
         p.nutrition_facts, p.cooking_time, p.meal_type, p.calories,
         p.protein, p.fats, p.carbs,
         coalesce((select array_agg(pt.user_id order by pt.user_id)
                     from public.post_tags pt where pt.post_id = p.id), '{}'),
         p.like_count, p.comment_count,
         exists (select 1 from public.post_likes pl
                  where pl.post_id = p.id and pl.user_id = (select uid from me)),
         pr.id, pr.username, pr.display_name, pr.photo_url,
         case when p.section_rank = 0 then 'following' else 'suggested' end
    from ranked p
    join public.profiles pr on pr.id = p.user_id
    left join public.media_assets ma_photo on ma_photo.id = p.photo_asset_id
    left join public.media_assets ma_video on ma_video.id = p.video_asset_id
   order by p.section_rank, p.score desc, p.created_at desc, p.id
   limit least(p_limit, 50)
   offset greatest(p_offset, 0);
$function$;

revoke all on function public.feed_page(integer, integer) from public, anon;
grant execute on function public.feed_page(integer, integer) to authenticated, service_role;
