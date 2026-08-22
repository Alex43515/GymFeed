-- Persistent, owner-only AI Coach history and rolling long-term memory.
-- The coach context contains private health, nutrition, and training data.

create table if not exists public.ai_coach_threads (
  user_id                    uuid primary key references public.profiles(id) on delete cascade,
  memory_summary             text not null default '',
  memory_through_message_id  bigint not null default 0,
  last_message_at            timestamptz,
  created_at                 timestamptz not null default now(),
  updated_at                 timestamptz not null default now()
);

create table if not exists public.ai_coach_messages (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  role        text not null check (role in ('user', 'assistant')),
  content     text not null check (char_length(content) between 1 and 20000),
  created_at  timestamptz not null default now()
);

create index if not exists ai_coach_messages_user_created_idx
  on public.ai_coach_messages (user_id, created_at desc, id desc);

alter table public.ai_coach_threads enable row level security;
alter table public.ai_coach_messages enable row level security;

drop policy if exists "read own ai coach thread" on public.ai_coach_threads;
create policy "read own ai coach thread"
  on public.ai_coach_threads for select
  using (auth.uid() = user_id);

drop policy if exists "create own ai coach thread" on public.ai_coach_threads;
create policy "create own ai coach thread"
  on public.ai_coach_threads for insert
  with check (auth.uid() = user_id);

drop policy if exists "update own ai coach thread" on public.ai_coach_threads;
create policy "update own ai coach thread"
  on public.ai_coach_threads for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "delete own ai coach thread" on public.ai_coach_threads;
create policy "delete own ai coach thread"
  on public.ai_coach_threads for delete
  using (auth.uid() = user_id);

drop policy if exists "read own ai coach messages" on public.ai_coach_messages;
create policy "read own ai coach messages"
  on public.ai_coach_messages for select
  using (auth.uid() = user_id);

drop policy if exists "create own ai coach messages" on public.ai_coach_messages;
create policy "create own ai coach messages"
  on public.ai_coach_messages for insert
  with check (auth.uid() = user_id);

drop policy if exists "delete own ai coach messages" on public.ai_coach_messages;
create policy "delete own ai coach messages"
  on public.ai_coach_messages for delete
  using (auth.uid() = user_id);

create or replace function public.touch_ai_coach_thread_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists ai_coach_threads_touch_updated_at
  on public.ai_coach_threads;
create trigger ai_coach_threads_touch_updated_at
before update on public.ai_coach_threads
for each row execute function public.touch_ai_coach_thread_updated_at();

revoke execute on function public.touch_ai_coach_thread_updated_at()
  from public, anon, authenticated;
