create or replace function public.marketing_studio_signup_report(p_days integer default 30)
returns jsonb
language sql stable security invoker
set search_path = ''
as $$
  with bounds as (
    select (now() at time zone 'Europe/Belgrade')::date as today,
           greatest(1, least(365, coalesce(p_days, 30))) as days
  ), registrations as (
    select occurred_at, publication_id, content_id, platform
    from public.marketing_events
    where event_name = 'signup'
  ), daily as (
    select (r.occurred_at at time zone 'Europe/Belgrade')::date as day, count(*) as count
    from registrations r cross join bounds b
    where r.occurred_at >= ((b.today - b.days + 1)::timestamp at time zone 'Europe/Belgrade')
    group by 1
  ), by_publication as (
    select publication_id, count(*) as count
    from registrations where publication_id is not null group by 1
  )
  select jsonb_build_object(
    'timezone', 'Europe/Belgrade',
    'total', (select count(*) from registrations),
    'current_profiles', (select count(*) from public.profiles),
    'latest_at', (select max(occurred_at) from registrations),
    'attributed', (select count(*) from registrations where publication_id is not null),
    'content_only', (select count(*) from registrations where content_id is not null and publication_id is null),
    'recent', (select coalesce(jsonb_agg(jsonb_build_object('at', occurred_at, 'platform', platform,
        'attributed', publication_id is not null) order by occurred_at desc), '[]'::jsonb)
      from (select * from registrations order by occurred_at desc limit 25) latest),
    'daily', (select jsonb_agg(jsonb_build_object('date', b.today - n, 'count', coalesce(d.count, 0)) order by n desc)
      from bounds b cross join lateral generate_series(0, b.days - 1) n
      left join daily d on d.day = b.today - n),
    'publications', coalesce((select jsonb_object_agg(publication_id::text, count) from by_publication), '{}'::jsonb)
  );
$$;
revoke all on function public.marketing_studio_signup_report(integer) from public, anon, authenticated;
grant execute on function public.marketing_studio_signup_report(integer) to service_role;
