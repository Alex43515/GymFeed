-- Founding Members: server-side number assignment (#0001-#1000).
--
-- * A number is assigned when a verified profile gets a username (the moment
--   the public GymFeed identity exists). Clients never write founding_members.
-- * Assignment is serialized with a transaction advisory lock, so two signups
--   at the same moment can never get the same number, and #1000 is the last.
-- * Test and demo accounts never get a number: test email domains, explicit
--   rows in founding_exclusions, and admins listed there.
-- * Existing real users are numbered by signup date with
--   select public.founding_backfill_existing();  (run once, at launch).

create table if not exists public.founding_exclusions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  reason text not null default '',
  created_at timestamptz not null default now()
);

comment on table public.founding_exclusions is
  'Accounts that must never receive a Founding number (test, demo, internal).';

alter table public.founding_exclusions enable row level security;
revoke all on public.founding_exclusions from anon, authenticated;

-- Demo / test email domains that are never real people.
create or replace function public.founding_is_test_email(p_email text)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(lower(split_part(p_email, '@', 2)), '') in (
    'gymfeed.test', 'example.com', 'example.org', 'test.com', 'test.test'
  );
$$;

create or replace function public.assign_founding_number(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing integer;
  next_number integer;
  user_email text;
begin
  if p_user_id is null then
    return null;
  end if;

  select founding_number into existing
  from public.founding_members where user_id = p_user_id;
  if existing is not null then
    return existing;
  end if;

  if exists (select 1 from public.founding_exclusions where user_id = p_user_id) then
    return null;
  end if;

  select email into user_email from auth.users where id = p_user_id;
  if user_email is null or public.founding_is_test_email(user_email) then
    return null;
  end if;

  if not exists (
    select 1 from public.profiles
    where id = p_user_id and nullif(btrim(username), '') is not null
  ) then
    return null;
  end if;

  -- One assignment at a time across the whole database.
  perform pg_advisory_xact_lock(hashtext('public.founding_members'));

  select founding_number into existing
  from public.founding_members where user_id = p_user_id;
  if existing is not null then
    return existing;
  end if;

  select coalesce(max(founding_number), 0) + 1 into next_number
  from public.founding_members;
  if next_number > 1000 then
    return null;
  end if;

  insert into public.founding_members (user_id, founding_number)
  values (p_user_id, next_number);
  return next_number;
end;
$$;

revoke all on function public.assign_founding_number(uuid) from public, anon, authenticated;

create or replace function public.founding_assign_on_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if nullif(btrim(new.username), '') is not null then
    perform public.assign_founding_number(new.id);
  end if;
  return new;
end;
$$;

revoke all on function public.founding_assign_on_profile() from public, anon, authenticated;

drop trigger if exists founding_assign_on_profile on public.profiles;
create trigger founding_assign_on_profile
  after insert or update of username on public.profiles
  for each row execute function public.founding_assign_on_profile();

-- What the app needs for the welcome popup and (optionally) a spots counter.
create or replace function public.founding_status()
returns table (founding_number integer, spots_left integer)
language sql
stable
security definer
set search_path = ''
as $$
  select
    (select fm.founding_number from public.founding_members fm
      where fm.user_id = auth.uid()),
    greatest(0, 1000 - (select count(*)::integer from public.founding_members));
$$;

revoke all on function public.founding_status() from public;
grant execute on function public.founding_status() to anon, authenticated;

-- Numbers existing real users by signup date. Safe to run more than once.
create or replace function public.founding_backfill_existing()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
  assigned integer := 0;
begin
  for r in
    select p.id from public.profiles p
    where nullif(btrim(p.username), '') is not null
      and not exists (select 1 from public.founding_members fm where fm.user_id = p.id)
    order by p.created_at, p.id
  loop
    if public.assign_founding_number(r.id) is not null then
      assigned := assigned + 1;
    end if;
  end loop;
  return assigned;
end;
$$;

revoke all on function public.founding_backfill_existing() from public, anon, authenticated;

-- Known non-people accounts.
insert into public.founding_exclusions (user_id, reason)
select p.id, 'GymFeed Demo marketplace account'
from public.profiles p where p.username = 'gymfeed_demo'
on conflict (user_id) do nothing;
