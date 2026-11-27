-- Integration assertions run in a rollback-only transaction. No real account,
-- counter, or campaign setting is changed by this test.
begin;
insert into auth.users(id, email, email_confirmed_at) values
 ('00000000-0000-4000-8000-000000000101', 'promo-test-1@example.invalid', now()),
 ('00000000-0000-4000-8000-000000000102', 'promo-test-2@example.invalid', now()),
 ('00000000-0000-4000-8000-000000000103', 'promo-test-3@example.invalid', now());
update promo_private.campaigns set enabled = true, max_claims = 2, claimed = 0,
 starts_at = now() - interval '1 day', ends_at = now() + interval '1 day'
 where code = 'GYMFEEDSTART';

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
do $$ begin
  if has_function_privilege('anon', 'public.android_promo(text,boolean)', 'execute')
     or has_table_privilege('authenticated', 'promo_private.campaigns', 'update')
     or has_table_privilege('authenticated', 'promo_private.claims', 'select') then
    raise exception 'Promo permissions are unsafe';
  end if;
  begin
    perform public.android_promo('wrong', false);
    raise exception 'Expected invalid code error';
  exception when others then
    if sqlerrm <> 'Invalid promo code.' then raise; end if;
  end;
  if (public.android_promo(' gymfeedstart ', false)->>'reserved')::boolean then
    raise exception 'Preview must not consume a place';
  end if;
  perform public.android_promo('GYMFEEDSTART', true);
  perform public.android_promo('GYMFEEDSTART', true);
end $$;
reset role;
do $$ begin
  if (select claimed from promo_private.campaigns where code='GYMFEEDSTART') <> 1 then
    raise exception 'Duplicate claims must be idempotent';
  end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
select public.android_promo('GYMFEEDSTART', true);
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000103', true);
do $$ begin
  begin
    perform public.android_promo('GYMFEEDSTART', true);
    raise exception 'Expected quota error';
  exception when others then
    if sqlerrm <> 'All 1,000 Android promo places have been claimed.' then raise; end if;
  end;
end $$;
reset role;
update promo_private.campaigns set ends_at = now() - interval '1 hour', starts_at = now() - interval '1 day' where code='GYMFEEDSTART';
set local role authenticated;
do $$ begin
  begin
    perform public.android_promo('GYMFEEDSTART', true);
    raise exception 'Expected expiry error';
  exception when others then
    if sqlerrm <> 'This promo has expired.' then raise; end if;
  end;
end $$;
reset role;
update promo_private.campaigns set ends_at = now() + interval '1 day' where code='GYMFEEDSTART';
insert into public.marketing_events(user_id, event_name, source, properties, dedupe_key)
 values ('00000000-0000-4000-8000-000000000103', 'subscription_started', 'revenuecat', '{"environment":"PRODUCTION"}', 'promo-integration-rollback-test');
set local role authenticated;
do $$ begin
  begin
    perform public.android_promo('GYMFEEDSTART', true);
    raise exception 'Expected existing subscriber error';
  exception when others then
    if sqlerrm <> 'This promo is for new subscribers only.' then raise; end if;
  end;
end $$;
reset role;
delete from auth.users where id='00000000-0000-4000-8000-000000000101';
do $$ begin
  if exists(select 1 from promo_private.claims where user_id='00000000-0000-4000-8000-000000000101')
     or (select claimed from promo_private.campaigns where code='GYMFEEDSTART') <> 2 then
    raise exception 'Account deletion must cascade without recycling the lifetime cap';
  end if;
end $$;
select 'PASS: permissions, normalization, preview, idempotency, quota, expiry, subscriber eligibility, account deletion' as result;
rollback;
