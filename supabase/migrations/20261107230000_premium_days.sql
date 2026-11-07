-- Premium days: time-based free Premium plus referral bonuses.
--
-- Rules (GymFeed Founding Members campaign, November 2026):
--   * Founding members get 7 free Premium days. A user counts as founding when
--     they hold a founding_members number, or while fewer than 1,000 numbers
--     have been handed out.
--   * Everyone after the first 1,000 gets 3 free Premium days.
--   * The free days start the first time the app asks for the user's status.
--     For accounts that existed before this release that is launch day.
--   * Inviting a friend adds 7 days to both people. An inviter can be credited
--     at most 4 times. A new account can redeem one invite, within 72 hours of
--     creating its profile.
--   * AI actions are capped at 40 per user per day (America/New_York date) to
--     protect the AI budget from abuse while free days are unlimited.
--
-- Paid subscriptions stay in RevenueCat. The app treats a user as premium when
-- RevenueCat reports the entitlement OR premium_until is in the future.
--
-- Clients can read their own rows but never write them. Every write goes
-- through the security definer functions below.

create table if not exists public.premium_access (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  trial_days integer not null check (trial_days between 0 and 31),
  trial_started_at timestamptz not null default now(),
  premium_until timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.premium_access is
  'Free Premium days per user (trial + referral bonuses). Owner read, server-only write.';

create table if not exists public.premium_referrals (
  invitee_id uuid primary key references public.profiles(id) on delete cascade,
  inviter_id uuid not null references public.profiles(id) on delete cascade,
  bonus_days integer not null default 7 check (bonus_days > 0),
  created_at timestamptz not null default now(),
  constraint premium_referrals_not_self check (invitee_id <> inviter_id)
);

create index if not exists premium_referrals_inviter_idx
  on public.premium_referrals (inviter_id);

comment on table public.premium_referrals is
  'One row per redeemed invite. Each invite gave both people bonus_days of Premium.';

create table if not exists public.ai_usage_daily (
  user_id uuid not null references public.profiles(id) on delete cascade,
  usage_day date not null,
  uses integer not null default 0 check (uses >= 0),
  refunds integer not null default 0 check (refunds >= 0),
  primary key (user_id, usage_day)
);

comment on table public.ai_usage_daily is
  'AI actions per user per America/New_York day, for the daily fair-use cap.';

alter table public.premium_access enable row level security;
alter table public.premium_referrals enable row level security;
alter table public.ai_usage_daily enable row level security;

drop policy if exists premium_access_owner_read on public.premium_access;
create policy premium_access_owner_read on public.premium_access
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists premium_referrals_party_read on public.premium_referrals;
create policy premium_referrals_party_read on public.premium_referrals
  for select to authenticated
  using (inviter_id = (select auth.uid()) or invitee_id = (select auth.uid()));

drop policy if exists ai_usage_daily_owner_read on public.ai_usage_daily;
create policy ai_usage_daily_owner_read on public.ai_usage_daily
  for select to authenticated using (user_id = (select auth.uid()));

revoke all on public.premium_access, public.premium_referrals, public.ai_usage_daily
  from anon, authenticated;
grant select on public.premium_access, public.premium_referrals, public.ai_usage_daily
  to authenticated;

-- Returns the user's premium_access row, creating it with the right number of
-- free days on first use. Internal: not callable by clients.
create or replace function public.premium_access_ensure(p_user uuid)
returns public.premium_access
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.premium_access;
  v_is_founding boolean := false;
  v_founding_count integer := 0;
  v_days integer;
begin
  select * into v_row from public.premium_access where user_id = p_user;
  if found then
    return v_row;
  end if;

  if not exists (select 1 from public.profiles where id = p_user) then
    return null;
  end if;

  -- founding_members ships in its own migration; read it only if present.
  if to_regclass('public.founding_members') is not null then
    execute 'select exists (select 1 from public.founding_members where user_id = $1),
                    (select count(*)::integer from public.founding_members)'
      into v_is_founding, v_founding_count
      using p_user;
  end if;

  v_days := case when v_is_founding or v_founding_count < 1000 then 7 else 3 end;

  insert into public.premium_access (user_id, trial_days, trial_started_at, premium_until)
  values (p_user, v_days, now(), now() + make_interval(days => v_days))
  on conflict (user_id) do nothing;

  select * into v_row from public.premium_access where user_id = p_user;
  return v_row;
end;
$$;

revoke all on function public.premium_access_ensure(uuid) from public, anon, authenticated;

-- Everything the app needs to show premium state and the Coach days block.
create or replace function public.get_premium_status()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.premium_access;
  v_invites integer;
  v_inviter text;
  v_profile_created timestamptz;
  v_redeemed boolean;
  v_uses integer;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  v_row := public.premium_access_ensure(v_uid);
  if v_row.user_id is null then
    raise exception 'profile not found' using errcode = 'P0002';
  end if;

  select count(*)::integer into v_invites
    from public.premium_referrals where inviter_id = v_uid;

  select p.username into v_inviter
    from public.premium_referrals r
    join public.profiles p on p.id = r.inviter_id
   where r.invitee_id = v_uid;
  v_redeemed := found;

  select created_at into v_profile_created from public.profiles where id = v_uid;

  select uses into v_uses from public.ai_usage_daily
   where user_id = v_uid
     and usage_day = (now() at time zone 'America/New_York')::date;

  return jsonb_build_object(
    'premium_until', v_row.premium_until,
    'seconds_left', greatest(0, floor(extract(epoch from (v_row.premium_until - now()))))::bigint,
    'trial_days', v_row.trial_days,
    'trial_started_at', v_row.trial_started_at,
    'invites_used', v_invites,
    'invites_max', 4,
    'referral_bonus_days', 7,
    'invited_by', v_inviter,
    'can_redeem_invite', (not v_redeemed) and v_profile_created > now() - interval '72 hours',
    'ai_uses_today', coalesce(v_uses, 0),
    'ai_daily_limit', 40
  );
end;
$$;

-- Credits an invite: +7 days to the new user and to the friend who invited
-- them. Returns {ok, code, ...}; code is one of ok, empty, not_found, self,
-- already_redeemed, too_late, inviter_limit.
create or replace function public.redeem_invite(p_username text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_name text := lower(regexp_replace(btrim(coalesce(p_username, '')), '^@+', ''));
  v_created timestamptz;
  v_inviter uuid;
  v_inviter_name text;
  v_until timestamptz;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;
  if v_name = '' then
    return jsonb_build_object('ok', false, 'code', 'empty');
  end if;

  select created_at into v_created from public.profiles where id = v_uid;
  if not found then
    raise exception 'profile not found' using errcode = 'P0002';
  end if;

  if exists (select 1 from public.premium_referrals where invitee_id = v_uid) then
    return jsonb_build_object('ok', false, 'code', 'already_redeemed');
  end if;
  if v_created < now() - interval '72 hours' then
    return jsonb_build_object('ok', false, 'code', 'too_late');
  end if;

  select id, username into v_inviter, v_inviter_name
    from public.profiles
   where lower(username) = v_name
   limit 1;
  if v_inviter is null then
    return jsonb_build_object('ok', false, 'code', 'not_found');
  end if;
  if v_inviter = v_uid then
    return jsonb_build_object('ok', false, 'code', 'self');
  end if;

  perform public.premium_access_ensure(v_uid);
  perform public.premium_access_ensure(v_inviter);

  -- Serialize invites for the same inviter so the cap of 4 holds under races.
  perform 1 from public.premium_access where user_id = v_inviter for update;
  if (select count(*) from public.premium_referrals where inviter_id = v_inviter) >= 4 then
    return jsonb_build_object('ok', false, 'code', 'inviter_limit', 'inviter', v_inviter_name);
  end if;

  insert into public.premium_referrals (invitee_id, inviter_id, bonus_days)
  values (v_uid, v_inviter, 7)
  on conflict (invitee_id) do nothing;
  if not found then
    return jsonb_build_object('ok', false, 'code', 'already_redeemed');
  end if;

  update public.premium_access
     set premium_until = greatest(premium_until, now()) + interval '7 days',
         updated_at = now()
   where user_id in (v_uid, v_inviter);

  select premium_until into v_until from public.premium_access where user_id = v_uid;

  return jsonb_build_object(
    'ok', true,
    'code', 'ok',
    'inviter', v_inviter_name,
    'premium_until', v_until,
    'bonus_days', 7
  );
end;
$$;

-- Counts one AI action against today's cap. Free days are checked here.
-- Paid status lives in RevenueCat on the device, so the client reports it in
-- p_client_paid; the daily cap applies either way.
-- Returns {allowed, reason, uses_today, daily_limit}; reason is one of
-- trial, paid, not_premium, daily_limit.
create or replace function public.claim_ai_use(p_client_paid boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_row public.premium_access;
  v_free boolean;
  v_day date := (now() at time zone 'America/New_York')::date;
  v_uses integer;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  v_row := public.premium_access_ensure(v_uid);
  v_free := v_row.user_id is not null and v_row.premium_until > now();

  if not (v_free or coalesce(p_client_paid, false)) then
    return jsonb_build_object('allowed', false, 'reason', 'not_premium',
                              'uses_today', 0, 'daily_limit', 40);
  end if;

  insert into public.ai_usage_daily as d (user_id, usage_day, uses)
  values (v_uid, v_day, 1)
  on conflict (user_id, usage_day) do update
     set uses = d.uses + 1
   where d.uses < 40
  returning d.uses into v_uses;

  if v_uses is null then
    return jsonb_build_object('allowed', false, 'reason', 'daily_limit',
                              'uses_today', 40, 'daily_limit', 40);
  end if;

  return jsonb_build_object(
    'allowed', true,
    'reason', case when v_free then 'trial' else 'paid' end,
    'uses_today', v_uses,
    'daily_limit', 40
  );
end;
$$;

-- Gives back one AI action when the AI provider failed. Capped at 10 refunds
-- per day so it cannot be used to sidestep the daily limit.
create or replace function public.refund_ai_use()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return;
  end if;
  update public.ai_usage_daily
     set uses = uses - 1,
         refunds = refunds + 1
   where user_id = v_uid
     and usage_day = (now() at time zone 'America/New_York')::date
     and uses > 0
     and refunds < 10;
end;
$$;

revoke all on function public.get_premium_status() from public, anon;
revoke all on function public.redeem_invite(text) from public, anon;
revoke all on function public.claim_ai_use(boolean) from public, anon;
revoke all on function public.refund_ai_use() from public, anon;
grant execute on function public.get_premium_status() to authenticated;
grant execute on function public.redeem_invite(text) to authenticated;
grant execute on function public.claim_ai_use(boolean) to authenticated;
grant execute on function public.refund_ai_use() to authenticated;
