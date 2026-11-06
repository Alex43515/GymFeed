-- Run against the deployed schema as postgres. All fixtures are rolled back.
-- No real files, posts, or user-owned assets are modified.
begin;

create temporary table media_upload_permission_fixtures as
select id as owner_id, gen_random_uuid() as asset_id
from public.profiles order by id limit 2;
grant select on media_upload_permission_fixtures to authenticated, service_role;

do $$
begin
  assert (select count(*) = 2 from media_upload_permission_fixtures),
    'Two existing profiles are required for ownership isolation QA';
end;
$$;

insert into public.media_assets (id, owner_id, kind, provider, status)
select asset_id, owner_id, 'video', 'bunny_stream', 'pending'
from media_upload_permission_fixtures;

select set_config('request.jwt.claim.sub',
  (select owner_id::text from media_upload_permission_fixtures order by owner_id limit 1), true);
select set_config('request.jwt.claim.role', 'authenticated', true);
set local role authenticated;

do $$
declare
  own_asset uuid;
  other_asset uuid;
  affected integer;
begin
  select asset_id into own_asset from media_upload_permission_fixtures
    where owner_id = auth.uid();
  select asset_id into other_asset from media_upload_permission_fixtures
    where owner_id <> auth.uid();

  -- Exact PATCH issued by uploadVideoToBunny, with SELECT/RETURNING coverage.
  update public.media_assets set status = 'uploading' where id = own_asset;
  get diagnostics affected = row_count;
  assert affected = 1, 'Owner must be able to start their pending upload';
  assert (select status = 'uploading' from public.media_assets where id = own_asset),
    'Owner must be able to read the updated status';

  update public.media_assets set status = 'uploading' where id = other_asset;
  get diagnostics affected = row_count;
  assert affected = 0, 'Another account must not change the upload';

  begin
    update public.media_assets set status = 'ready' where id = own_asset;
    raise exception 'Client incorrectly allowed to mark media ready';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.media_assets set bunny_video_guid = gen_random_uuid()::text where id = own_asset;
    raise exception 'Client incorrectly allowed to change Bunny ownership manifest';
  exception when insufficient_privilege then null;
  end;

  begin
    update public.media_assets set owner_id = gen_random_uuid() where id = own_asset;
    raise exception 'Client incorrectly allowed to reassign ownership';
  exception when insufficient_privilege then null;
  end;

  begin
    insert into public.media_assets(owner_id, kind, provider)
      values(auth.uid(), 'video', 'bunny_stream');
    raise exception 'Client incorrectly allowed to forge an upload ticket';
  exception when insufficient_privilege then null;
  end;

  begin
    delete from public.media_assets where id = own_asset;
    raise exception 'Client incorrectly allowed to delete ownership manifest';
  exception when insufficient_privilege then null;
  end;
end;
$$;

reset role;
-- The backend must still be able to process/complete the file.
set local role service_role;
update public.media_assets set status = 'ready'
where id in (select asset_id from media_upload_permission_fixtures);
reset role;
set local role authenticated;
do $$
declare affected integer;
begin
  update public.media_assets set status = 'uploading'
    where id in (select asset_id from media_upload_permission_fixtures);
  get diagnostics affected = row_count;
  assert affected = 0, 'Client must not overwrite webhook completion';
end;
$$;
reset role;

do $$
begin
  assert not has_column_privilege('anon', 'public.media_assets', 'status', 'UPDATE'),
    'Anonymous status writes must remain denied';
  assert not has_table_privilege('authenticated', 'public.media_assets', 'UPDATE'),
    'Full-table UPDATE must remain denied';
end;
$$;

rollback;
select 'PASS: upload status, ownership isolation, protected identifiers, webhook completion, and anonymous denial; fixtures rolled back' as result;
