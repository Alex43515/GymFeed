-- Store billing remains the only authority that grants paid Premium.
-- Reservations are durable/idempotent: an uncertain billing result cannot free
-- a slot while a discounted purchase might still complete.
create schema if not exists promo_private;
revoke all on schema promo_private from public, anon;
grant usage on schema promo_private to authenticated;

create table promo_private.campaigns (
  code text primary key,
  enabled boolean not null default false,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  max_claims integer not null check (max_claims > 0),
  claimed integer not null default 0 check (claimed >= 0 and claimed <= max_claims),
  check (ends_at > starts_at)
);
create table promo_private.claims (
  code text not null references promo_private.campaigns(code),
  user_id uuid not null references auth.users(id),
  claimed_at timestamptz not null default now(),
  primary key (code, user_id)
);
create index promo_claims_user_idx on promo_private.claims(user_id);
alter table promo_private.campaigns enable row level security;
alter table promo_private.claims enable row level security;
revoke all on promo_private.campaigns, promo_private.claims from public, anon, authenticated;

insert into promo_private.campaigns(code, starts_at, ends_at, max_claims)
values ('GYMFEEDSTART', '2026-11-27T00:00:00Z', '2027-01-15T08:00:00Z', 1000);

create function promo_private.android_promo(p_code text, p_claim boolean)
returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
  v_campaign promo_private.campaigns%rowtype;
  v_claimed boolean;
begin
  if v_uid is null then
    raise exception 'Please sign in to use a promo code.' using errcode = '42501';
  end if;
  if not exists (select 1 from auth.users where id = v_uid and email_confirmed_at is not null) then
    raise exception 'Confirm your email before using a promo code.';
  end if;
  -- Row lock serializes the cap check and allocation, including concurrent calls.
  select * into v_campaign from promo_private.campaigns
    where code = upper(trim(p_code)) for update;
  if not found then raise exception 'Invalid promo code.'; end if;
  if not v_campaign.enabled then raise exception 'This promo is not available yet.'; end if;
  if now() < v_campaign.starts_at then raise exception 'This promo has not started yet.'; end if;
  if now() >= v_campaign.ends_at then raise exception 'This promo has expired.'; end if;
  if exists (select 1 from public.marketing_events
    where user_id = v_uid and source = 'revenuecat'
      and event_name in ('subscription_started', 'subscription_renewed')
      and coalesce(properties->>'environment', 'PRODUCTION') <> 'SANDBOX') then
    raise exception 'This promo is for new subscribers only.';
  end if;
  select exists(select 1 from promo_private.claims where code = v_campaign.code and user_id = v_uid) into v_claimed;
  if not v_claimed then
    if v_campaign.claimed >= v_campaign.max_claims then
      raise exception 'All 1,000 Android promo places have been claimed.';
    end if;
    if p_claim then
      insert into promo_private.claims(code, user_id) values (v_campaign.code, v_uid);
      update promo_private.campaigns set claimed = claimed + 1 where code = v_campaign.code;
    end if;
  end if;
  return jsonb_build_object('code', v_campaign.code, 'offer_id', 'gymfeedstart',
    'ends_at', v_campaign.ends_at, 'reserved', v_claimed or p_claim);
end;
$$;
revoke all on function promo_private.android_promo(text, boolean) from public, anon;
grant execute on function promo_private.android_promo(text, boolean) to authenticated;

create function public.android_promo(p_code text, p_claim boolean default false)
returns jsonb language sql security invoker set search_path = ''
as $$ select promo_private.android_promo(p_code, p_claim); $$;
revoke all on function public.android_promo(text, boolean) from public, anon;
grant execute on function public.android_promo(text, boolean) to authenticated;
