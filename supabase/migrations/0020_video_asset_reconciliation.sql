-- Reconnect videos created by older clients to the media_assets rows that
-- were created by create-upload. Those clients stored the Bunny HLS URL but
-- forgot video_asset_id and uploaded an animated GIF as video_thumbnail.

update public.posts as p
set
  video_asset_id = (
    select ma.id
    from public.media_assets as ma
    where ma.owner_id = p.user_id
      and ma.kind = 'video'
      and ma.bunny_video_guid is not null
      and p.legacy_video_url like '%/' || ma.bunny_video_guid || '/%'
    order by ma.created_at desc
    limit 1
  ),
  video_thumbnail = coalesce(
    (
      select nullif(ma.thumbnail_url, '')
      from public.media_assets as ma
      where ma.owner_id = p.user_id
        and ma.kind = 'video'
        and ma.bunny_video_guid is not null
        and p.legacy_video_url like '%/' || ma.bunny_video_guid || '/%'
      order by ma.created_at desc
      limit 1
    ),
    p.video_thumbnail
  )
where p.video_asset_id is null
  and coalesce(p.legacy_video_url, '') <> ''
  and exists (
    select 1
    from public.media_assets as ma
    where ma.owner_id = p.user_id
      and ma.kind = 'video'
      and ma.bunny_video_guid is not null
      and p.legacy_video_url like '%/' || ma.bunny_video_guid || '/%'
  );

update public.user_trainings as t
set video_asset_id = (
  select ma.id
  from public.media_assets as ma
  where ma.owner_id = t.user_id
    and ma.kind = 'video'
    and ma.bunny_video_guid is not null
    and t.legacy_video_url like '%/' || ma.bunny_video_guid || '/%'
  order by ma.created_at desc
  limit 1
)
where t.video_asset_id is null
  and coalesce(t.legacy_video_url, '') <> ''
  and exists (
    select 1
    from public.media_assets as ma
    where ma.owner_id = t.user_id
      and ma.kind = 'video'
      and ma.bunny_video_guid is not null
      and t.legacy_video_url like '%/' || ma.bunny_video_guid || '/%'
  );
