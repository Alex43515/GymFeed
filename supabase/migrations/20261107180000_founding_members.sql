-- Founding Members: the first 1,000 profiles get a permanent number (#0001–#1000)
-- shown as a badge on their profile and next to their name in the feed.
--
-- Readable by anyone (the badge is public). Clients can never write here:
-- numbers are assigned only by server code (security definer / service role),
-- which lands with the Founding program migration.
-- Premium days are deliberately NOT stored here; they belong in a private,
-- server-only table.

create table if not exists public.founding_members (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  founding_number integer not null unique
    check (founding_number between 1 and 1000),
  created_at timestamptz not null default now()
);

comment on table public.founding_members is
  'Founding Member numbers (#0001-#1000). Public read, server-only write.';

alter table public.founding_members enable row level security;

drop policy if exists founding_members_public_read on public.founding_members;
create policy founding_members_public_read
  on public.founding_members
  for select
  to anon, authenticated
  using (true);

revoke insert, update, delete, truncate on public.founding_members
  from anon, authenticated;
grant select on public.founding_members to anon, authenticated;
