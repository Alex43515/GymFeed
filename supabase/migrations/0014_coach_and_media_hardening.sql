-- Keep body-scan analytics separate from legacy progress-photo slot state.
alter table public.profile_private
  add column if not exists body_scan_count int not null default 0;

alter table public.profile_private
  drop constraint if exists profile_private_body_scan_count_valid;
alter table public.profile_private
  add constraint profile_private_body_scan_count_valid
  check (body_scan_count >= 0);

-- Dated Coach usage is required for the "This week" summary. The older
-- profile_private counters remain as compatibility totals for older clients.
create table if not exists public.coach_activity_log (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  tool text not null check (tool in ('equipment_scan', 'body_scan')),
  photo_url text not null default '',
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists coach_activity_log_user_created_idx
  on public.coach_activity_log (user_id, created_at desc);

alter table public.coach_activity_log enable row level security;

drop policy if exists "read own coach activity" on public.coach_activity_log;
create policy "read own coach activity"
  on public.coach_activity_log for select
  using (auth.uid() = user_id);

drop policy if exists "create own coach activity" on public.coach_activity_log;
create policy "create own coach activity"
  on public.coach_activity_log for insert
  with check (auth.uid() = user_id);

drop policy if exists "delete own coach activity" on public.coach_activity_log;
create policy "delete own coach activity"
  on public.coach_activity_log for delete
  using (auth.uid() = user_id);

-- A media asset needs its playable URL; thumbnail_url is never a video source.
alter table public.media_assets
  add column if not exists playback_url text;

update public.media_assets
   set playback_url = 'https://vz-55fc89c2-aab.b-cdn.net/' ||
                      bunny_video_guid || '/playlist.m3u8'
 where provider = 'bunny_stream'
   and bunny_video_guid is not null
   and coalesce(playback_url, '') = '';

create or replace function public.reels_page(
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
         p.legacy_photo_url,
         coalesce(nullif(ma_video.playback_url, ''), p.legacy_video_url),
         coalesce(nullif(ma_video.thumbnail_url, ''), p.video_thumbnail),
         coalesce(ma_video.blurhash, ''),
         p.food_post, p.like_count, p.comment_count,
         exists (select 1 from post_likes pl
                 where pl.post_id = p.id and pl.user_id = auth.uid()),
         pr.id, pr.username, pr.display_name, pr.photo_url
    from posts p
    join profiles pr on pr.id = p.user_id
    left join media_assets ma_video on ma_video.id = p.video_asset_id
   where not p.deleted
     and coalesce(nullif(ma_video.playback_url, ''), p.legacy_video_url, '') <> ''
     and not exists (select 1 from user_blocks b
                     where (b.blocker_id = auth.uid() and b.blocked_id = p.user_id)
                        or (b.blocker_id = p.user_id and b.blocked_id = auth.uid()))
   order by p.created_at desc
   limit least(p_limit, 20)
   offset greatest(p_offset, 0);
$$;
