-- Bunny videos were stored without playback_url: the deployed create-upload
-- function (v6) predates the column, so every new upload left it NULL. Posts
-- did not notice (they keep the playlist URL on the post), but training-plan
-- intro and exercise videos read it from media_assets.
--
-- Derive it from the Bunny GUID on every insert/update, and backfill existing
-- rows, the same way 0014_coach_and_media_hardening did once.

create or replace function public.fill_media_asset_playback_url()
returns trigger
language plpgsql
set search_path = public, pg_temp
as $$
begin
  if new.kind = 'video'
     and new.provider = 'bunny_stream'
     and coalesce(new.bunny_video_guid, '') <> ''
     and coalesce(new.playback_url, '') = '' then
    new.playback_url := 'https://vz-55fc89c2-aab.b-cdn.net/' || new.bunny_video_guid || '/playlist.m3u8';
  end if;
  return new;
end;
$$;

drop trigger if exists media_assets_fill_playback_url on public.media_assets;
create trigger media_assets_fill_playback_url
before insert or update on public.media_assets
for each row execute function public.fill_media_asset_playback_url();

revoke execute on function public.fill_media_asset_playback_url() from public, anon, authenticated;

update public.media_assets
   set playback_url = 'https://vz-55fc89c2-aab.b-cdn.net/' || bunny_video_guid || '/playlist.m3u8'
 where kind = 'video'
   and provider = 'bunny_stream'
   and coalesce(bunny_video_guid, '') <> ''
   and coalesce(playback_url, '') = '';
