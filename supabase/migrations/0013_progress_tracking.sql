-- Editable monthly progress history. Health data stays owner-only.
create table if not exists public.progress_entries (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references public.profiles(id) on delete cascade,
  month_start           date not null,
  photo_url             text not null default '',
  weight_kg             numeric(6,2),
  body_fat_percentage   numeric(5,2),
  note                  text not null default '',
  legacy_slot           int,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  constraint progress_entries_user_month_unique unique (user_id, month_start),
  constraint progress_entries_weight_valid
    check (weight_kg is null or weight_kg between 20 and 500),
  constraint progress_entries_body_fat_valid
    check (body_fat_percentage is null or body_fat_percentage between 1 and 75),
  constraint progress_entries_legacy_slot_valid
    check (legacy_slot is null or legacy_slot between 0 and 6)
);

create index if not exists progress_entries_user_month_idx
  on public.progress_entries (user_id, month_start desc);

alter table public.progress_entries enable row level security;

drop policy if exists "read own progress" on public.progress_entries;
create policy "read own progress"
  on public.progress_entries for select
  using (auth.uid() = user_id);

drop policy if exists "create own progress" on public.progress_entries;
create policy "create own progress"
  on public.progress_entries for insert
  with check (auth.uid() = user_id);

drop policy if exists "update own progress" on public.progress_entries;
create policy "update own progress"
  on public.progress_entries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "delete own progress" on public.progress_entries;
create policy "delete own progress"
  on public.progress_entries for delete
  using (auth.uid() = user_id);

do $$
begin
  alter publication supabase_realtime add table public.progress_entries;
exception
  when duplicate_object then null;
end;
$$;

