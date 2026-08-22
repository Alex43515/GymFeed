-- Verification-first signup and authoritative username reservations.
--
-- A Supabase Auth row must exist before Supabase can send a confirmation
-- email, but an unverified identity must not appear as a GymFeed profile.
-- Usernames are reserved in the same transaction as auth.users insertion so
-- two concurrent signups cannot claim the same name with different casing.

create table if not exists public.signup_username_reservations (
  user_id uuid primary key references auth.users (id) on delete cascade,
  username text not null,
  normalized_username text generated always as (lower(btrim(username))) stored,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  constraint signup_username_format check (
    btrim(username) ~ '^[A-Za-z0-9_]{3,30}$'
  )
);

alter table public.signup_username_reservations
  add column if not exists expires_at timestamptz
  not null default (now() + interval '24 hours');

create unique index if not exists signup_username_reservations_normalized_key
  on public.signup_username_reservations (normalized_username);

alter table public.signup_username_reservations enable row level security;
revoke all on table public.signup_username_reservations from anon, authenticated;

-- Return only an availability boolean. The function deliberately does not
-- expose pending email addresses or auth identities to anonymous clients.
create or replace function public.is_username_available(candidate text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    btrim(candidate) ~ '^[A-Za-z0-9_]{3,30}$'
    and not exists (
      select 1
      from public.profiles p
      where lower(btrim(p.username)) = lower(btrim(candidate))
    )
    and not exists (
      select 1
      from public.signup_username_reservations r
      where r.normalized_username = lower(btrim(candidate))
        and r.expires_at > now()
    );
$$;

revoke all on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon, authenticated;

-- Preserve the existing trigger name, but delay public/private profile rows
-- until the email is confirmed. OAuth identities arrive confirmed and are
-- provisioned immediately. Email/password identities only reserve a username.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_username text := nullif(btrim(new.raw_user_meta_data ->> 'username'), '');
  requested_name text := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''),
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    ''
  );
  requested_photo text := coalesce(
    nullif(btrim(new.raw_user_meta_data ->> 'avatar_url'), ''),
    ''
  );
begin
  if requested_username is not null then
    delete from public.signup_username_reservations
    where normalized_username = lower(requested_username)
      and expires_at <= now();

    insert into public.signup_username_reservations (user_id, username)
    values (new.id, requested_username)
    on conflict (user_id) do update
      set username = excluded.username,
          expires_at = now() + interval '24 hours';
  end if;

  if new.email_confirmed_at is null then
    return new;
  end if;

  insert into public.profiles (id, username, display_name, photo_url)
  values (new.id, requested_username, requested_name, requested_photo)
  on conflict (id) do update set
    username = coalesce(excluded.username, public.profiles.username),
    display_name = case
      when excluded.display_name = '' then public.profiles.display_name
      else excluded.display_name
    end,
    photo_url = case
      when excluded.photo_url = '' then public.profiles.photo_url
      else excluded.photo_url
    end;

  insert into public.profile_private (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do update
    set email = excluded.email;

  delete from public.signup_username_reservations where user_id = new.id;
  return new;
end;
$$;

-- The original INSERT trigger already invokes handle_new_user(). Add the
-- confirmation transition for password signups.
drop trigger if exists on_auth_user_email_verified on auth.users;
create trigger on_auth_user_email_verified
  after update of email_confirmed_at on auth.users
  for each row
  when (old.email_confirmed_at is null and new.email_confirmed_at is not null)
  execute function public.handle_new_user();

-- The original schema used a case-sensitive unique constraint. Enforce the
-- product rule case-insensitively for all future inserts and username edits,
-- without making this migration fail on any legacy duplicate data.
create or replace function public.enforce_profile_username_uniqueness()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.username is not null and exists (
    select 1
    from public.profiles p
    where p.id <> new.id
      and lower(btrim(p.username)) = lower(btrim(new.username))
  ) then
    raise unique_violation using message = 'Username is already taken';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_username_case_insensitive on public.profiles;
create trigger profiles_username_case_insensitive
  before insert or update of username on public.profiles
  for each row execute function public.enforce_profile_username_uniqueness();

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.enforce_profile_username_uniqueness()
  from public, anon, authenticated;
