-- ============================================================================
-- GymFeed — Supabase initial schema
-- Mirrors the Firestore data model (lib/backend/schema/*_record.dart) with
-- Firestore anti-patterns normalized:
--   * DocumentReference fields        -> foreign keys
--   * arrays of refs (likes, views…) -> join tables (no 1MB doc limit)
--   * subcollections                  -> flat tables with FKs
--   * public PII (audit finding)      -> split into profile_private, owner-only
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
create type media_kind as enum ('image', 'video');
create type media_provider as enum ('supabase', 'bunny_stream');
create type media_status as enum ('pending', 'uploading', 'processing', 'ready', 'failed', 'quarantined');
create type bookmark_kind as enum ('post', 'food_post', 'training');

-- ---------------------------------------------------------------------------
-- profiles — public part of users/{uid}
-- PK equals auth.users.id (Firebase UIDs are preserved on auth import)
-- ---------------------------------------------------------------------------
create table profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  username      text unique,
  display_name  text not null default '',
  photo_url     text not null default '',
  bio           text not null default '',
  website       text not null default '',
  custom_link   text not null default '',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- profile_private — PII + health data from users/{uid}, readable by owner only
-- (fixes Firestore rule `users: allow read: if true` exposing email/phone/
--  birthday/body metrics to the public internet)
-- ---------------------------------------------------------------------------
create table profile_private (
  id             uuid primary key references profiles (id) on delete cascade,
  email          text not null default '',
  phone_number   text not null default '',
  birthday       date,
  enable_email   boolean not null default false,
  -- onboarding / AI-coach answers
  gender         boolean not null default false,
  age            int not null default 0,
  height_cm      int not null default 0,
  weight_kg      int not null default 0,
  workout_level  text not null default '',
  goals          text not null default '',
  workouts       text not null default '',
  workout_length text not null default '',
  workout_period text not null default '',
  meals          text not null default '',
  snacks         int not null default 0,
  days           int not null default 0,
  gpt_prompt     text not null default '',
  personal_trainer_suggestions text not null default '',
  vision_url     text not null default '',
  progress_image  text not null default '',
  progress_image2 text not null default '',
  progress_image3 text not null default '',
  -- body-composition results (b_fat/e_fat/lean_mass custom actions)
  lean_mass_index int not null default 0,
  fat_mass_index  int not null default 0,
  ufat2 double precision not null default 0,
  bfat2 double precision not null default 0,
  efat2 double precision not null default 0,
  lean_mass2 double precision not null default 0,
  -- scanner counters / feature-gating counters kept for app parity
  gpt_button int not null default 0,
  vision_button int not null default 0,
  button_click int not null default 0,
  calories_scanner int not null default 0,
  fats_scanner int not null default 0,
  protein_scanner int not null default 0,
  carbs_scanner int not null default 0,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- media_assets — backbone of the media pipeline (new; replaces raw URL strings)
-- Firestore stored bare download URLs; here every uploaded file has a row that
-- tracks provider, processing status and display metadata (blurhash etc.).
-- ---------------------------------------------------------------------------
create table media_assets (
  id               uuid primary key default gen_random_uuid(),
  owner_id         uuid not null references profiles (id) on delete cascade,
  kind             media_kind not null,
  provider         media_provider not null,
  storage_path     text,          -- supabase storage object path (images)
  bunny_video_guid text,          -- bunny stream GUID (videos)
  status           media_status not null default 'pending',
  width            int,
  height           int,
  duration_seconds double precision,
  bytes            bigint,
  blurhash         text,
  thumbnail_url    text,
  preview_url      text,          -- animated preview (bunny generates webp)
  created_at       timestamptz not null default now()
);
create index media_assets_owner_idx on media_assets (owner_id, created_at desc);
create index media_assets_status_idx on media_assets (status) where status in ('pending', 'processing');

-- ---------------------------------------------------------------------------
-- posts — posts collection (regular + food posts share one table, as in
-- Firestore where food_post bool discriminates)
-- ---------------------------------------------------------------------------
create table posts (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references profiles (id) on delete cascade,
  created_at     timestamptz not null default now(),
  caption        text not null default '',
  photo_asset_id uuid references media_assets (id),
  video_asset_id uuid references media_assets (id),
  -- legacy URL columns kept during migration so old clients keep working;
  -- dropped once all media rows are backfilled into media_assets
  legacy_photo_url text not null default '',
  legacy_video_url text not null default '',
  video_thumbnail  text not null default '',
  video_preview    text not null default '',
  allow_comments boolean not null default true,
  allow_likes    boolean not null default true,
  location       text not null default '',
  exact_lat      double precision,
  exact_lng      double precision,
  call_to_action_enabled boolean not null default false,
  call_to_action_text    text not null default '',
  call_to_action_link    text not null default '',
  labels         text not null default '',
  deleted        boolean not null default false,
  -- food-post fields (food_post = true)
  food_post      boolean not null default false,
  food_title     text not null default '',
  food_description text not null default '',
  recipe         text not null default '',
  nutrition_facts text not null default '',
  cooking_time   text not null default '',
  meal_type      text not null default '',
  calories       int not null default 0,
  protein        int not null default 0,
  fats           text not null default '',
  carbs          text not null default '',
  -- denormalized counters maintained by triggers (were numComments /
  -- likes-array-length in Firestore)
  like_count     int not null default 0,
  comment_count  int not null default 0
);
create index posts_feed_idx on posts (created_at desc, id desc) where not deleted;
create index posts_user_idx on posts (user_id, created_at desc) where not deleted;
create index posts_food_idx on posts (food_post, created_at desc) where not deleted;

create table post_likes (
  post_id    uuid not null references posts (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);
create index post_likes_user_idx on post_likes (user_id);

create table post_tags (
  post_id uuid not null references posts (id) on delete cascade,
  user_id uuid not null references profiles (id) on delete cascade,
  primary key (post_id, user_id)
);

-- posts/{id}/comments subcollection -> comments; foodcomments collection ->
-- same table with is_food flag (was a separate top-level collection)
create table comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references posts (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  body       text not null,
  is_food    boolean not null default false,
  created_at timestamptz not null default now()
);
create index comments_post_idx on comments (post_id, created_at desc);

create table comment_likes (
  comment_id uuid not null references comments (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  primary key (comment_id, user_id)
);

-- ---------------------------------------------------------------------------
-- stories — stories collection; views array -> story_views
-- ---------------------------------------------------------------------------
create table stories (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references profiles (id) on delete cascade,
  photo_asset_id uuid references media_assets (id),
  video_asset_id uuid references media_assets (id),
  legacy_photo_url text not null default '',
  legacy_video_url text not null default '',
  created_at     timestamptz not null default now(),
  expires_at     timestamptz not null default now() + interval '24 hours'
);
create index stories_active_idx on stories (expires_at desc);
create index stories_user_idx on stories (user_id, created_at desc);

create table story_views (
  story_id  uuid not null references stories (id) on delete cascade,
  viewer_id uuid not null references profiles (id) on delete cascade,
  viewed_at timestamptz not null default now(),
  primary key (story_id, viewer_id)
);

-- ---------------------------------------------------------------------------
-- follows — replaces users.following array + users/{id}/followers subcollection
-- ---------------------------------------------------------------------------
create table follows (
  follower_id uuid not null references profiles (id) on delete cascade,
  followee_id uuid not null references profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);
create index follows_followee_idx on follows (followee_id);

create table user_blocks (
  blocker_id uuid not null references profiles (id) on delete cascade,
  blocked_id uuid not null references profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

-- ---------------------------------------------------------------------------
-- bookmarks — users/{id}/bookmarks arrays (postRefs / foodPostRef /
-- postTrainingRef) + users.reelsSaved array -> one row per saved item
-- ---------------------------------------------------------------------------
create table bookmarks (
  user_id     uuid not null references profiles (id) on delete cascade,
  kind        bookmark_kind not null,
  post_id     uuid references posts (id) on delete cascade,
  training_id uuid, -- FK added after user_trainings below
  created_at  timestamptz not null default now(),
  check (num_nonnulls(post_id, training_id) = 1)
);
create unique index bookmarks_post_uq on bookmarks (user_id, post_id) where post_id is not null;
create unique index bookmarks_training_uq on bookmarks (user_id, training_id) where training_id is not null;

-- ---------------------------------------------------------------------------
-- chats / chat_members / chat_messages
-- chats.users array + users/{id}/chatRefs subcollection -> chat_members
-- ---------------------------------------------------------------------------
create table chats (
  id                   uuid primary key default gen_random_uuid(),
  created_at           timestamptz not null default now(),
  last_message         text not null default '',
  last_message_at      timestamptz,
  last_message_sent_by uuid references profiles (id)
);

create table chat_members (
  chat_id      uuid not null references chats (id) on delete cascade,
  user_id      uuid not null references profiles (id) on delete cascade,
  joined_at    timestamptz not null default now(),
  last_seen_at timestamptz, -- replaces chats.lastMessageSeenBy array
  primary key (chat_id, user_id)
);
create index chat_members_user_idx on chat_members (user_id);

create table chat_messages (
  id         uuid primary key default gen_random_uuid(),
  chat_id    uuid not null references chats (id) on delete cascade,
  user_id    uuid not null references profiles (id) on delete cascade,
  text       text not null default '',
  image_url  text not null default '',
  video_url  text not null default '',
  post_id    uuid references posts (id) on delete set null,    -- shared post
  comment_id uuid references comments (id) on delete set null, -- shared comment
  created_at timestamptz not null default now()
);
create index chat_messages_chat_idx on chat_messages (chat_id, created_at desc);

-- ---------------------------------------------------------------------------
-- notifications — users/{id}/notifications subcollection +
-- users.unreadNotifications array -> read flag
-- ---------------------------------------------------------------------------
create table notifications (
  id           uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references profiles (id) on delete cascade,
  actor_id     uuid references profiles (id) on delete cascade,
  type         text not null,  -- like / comment / follow / … (was notificationType string)
  post_id      uuid references posts (id) on delete cascade,
  comment_id   uuid references comments (id) on delete cascade,
  read         boolean not null default false,
  created_at   timestamptz not null default now()
);
create index notifications_recipient_idx on notifications (recipient_id, created_at desc);
create index notifications_unread_idx on notifications (recipient_id) where not read;

-- ---------------------------------------------------------------------------
-- recent_searches — users/{id}/recent_searches subcollection
-- ---------------------------------------------------------------------------
create table recent_searches (
  owner_id         uuid not null references profiles (id) on delete cascade,
  searched_user_id uuid not null references profiles (id) on delete cascade,
  searched_at      timestamptz not null default now(),
  primary key (owner_id, searched_user_id)
);

-- ---------------------------------------------------------------------------
-- workout log + exercise sessions (personal, non-social)
-- ---------------------------------------------------------------------------
create table workout_entries (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references profiles (id) on delete cascade,
  exercise_name text not null default '',   -- exerciseFirstName
  description text not null default '',
  day         text not null default '',
  date        timestamptz,
  kg          int not null default 0,
  sets        int not null default 0,
  reps        int not null default 0,
  intensity   text not null default '',     -- was `intensety`
  est_time    int not null default 0,
  is_checked  boolean not null default false,
  created_at  timestamptz not null default now()
);
create index workout_entries_user_idx on workout_entries (user_id, date desc);

create table exercise_sessions (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references profiles (id) on delete cascade,
  name         text not null default '',    -- exerciseSessionName
  description  text not null default '',
  sets         int not null default 0,
  reps         int not null default 0,
  kg           int not null default 0,
  intensity    text not null default '',
  rest_time    int not null default 0,      -- was `eestTime`
  is_checked   boolean not null default false,
  created_at   timestamptz not null default now()
);
create index exercise_sessions_user_idx on exercise_sessions (user_id);

-- ---------------------------------------------------------------------------
-- user_trainings — group training sessions / reels source
-- trainingAttendees + users.trainingsJoined arrays -> training_participants
-- ---------------------------------------------------------------------------
create table user_trainings (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references profiles (id) on delete cascade,
  title            text not null default '',
  description      text not null default '',
  category         text not null default '',
  difficulty_level text not null default '',
  -- Firestore stored date/time as free-text strings; kept as text for app
  -- parity, plus a parsed timestamptz column to enable proper queries
  training_date_raw text not null default '',
  training_time_raw text not null default '',
  starts_at        timestamptz,
  duration         int not null default 0,
  session_duration int not null default 0,
  legacy_id        int not null default 0,  -- idTrainings
  video_asset_id   uuid references media_assets (id),
  legacy_video_url text not null default '',
  background_image text not null default '',
  location_lat     double precision,
  location_lng     double precision,
  like_count       int not null default 0,
  created_at       timestamptz not null default now()
);
create index user_trainings_reels_idx on user_trainings (created_at desc, id desc) where video_asset_id is not null or legacy_video_url <> '';
create index user_trainings_owner_idx on user_trainings (user_id);

alter table bookmarks
  add constraint bookmarks_training_fk
  foreign key (training_id) references user_trainings (id) on delete cascade;

create table training_participants (
  training_id uuid not null references user_trainings (id) on delete cascade,
  user_id     uuid not null references profiles (id) on delete cascade,
  joined_at   timestamptz not null default now(),
  primary key (training_id, user_id)
);
create index training_participants_user_idx on training_participants (user_id);

create table training_likes (
  training_id uuid not null references user_trainings (id) on delete cascade,
  user_id     uuid not null references profiles (id) on delete cascade,
  primary key (training_id, user_id)
);

-- ---------------------------------------------------------------------------
-- meal_scans — mealScanner collection (AI meal scanner results)
-- ---------------------------------------------------------------------------
create table meal_scans (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references profiles (id) on delete cascade,
  dish_name    text not null default '',
  description  text not null default '',
  gemini_parse text not null default '',
  calories     int not null default 0,
  protein      int not null default 0,
  carbs        int not null default 0,
  fats         int not null default 0,
  is_checked   boolean not null default false,
  is_marked    boolean not null default false,
  scanned_on   timestamptz,
  created_at   timestamptz not null default now()
);
create index meal_scans_user_idx on meal_scans (user_id, scanned_on desc);

-- ---------------------------------------------------------------------------
-- reports / admin
-- ---------------------------------------------------------------------------
create table reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles (id) on delete set null,
  post_ref    text not null default '',  -- was a string path in Firestore
  post_image  text not null default '',
  details     text not null default '',
  created_at  timestamptz not null default now()
);

create table administrative (
  id        uuid primary key default gen_random_uuid(),
  usernames text[] not null default '{}'
);

create table verification_dash (
  id        uuid primary key default gen_random_uuid(),
  usernames text[] not null default '{}'
);

-- ---------------------------------------------------------------------------
-- push notifications — fcm_tokens subcollection + ff_push_notifications queue
-- FCM keeps working without Firestore; an Edge Function worker drains
-- push_queue via the FCM HTTP v1 API.
-- ---------------------------------------------------------------------------
create table fcm_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references profiles (id) on delete cascade,
  token       text not null unique,
  device_type text not null default '',
  created_at  timestamptz not null default now()
);
create index fcm_tokens_user_idx on fcm_tokens (user_id);

create table push_queue (
  id            uuid primary key default gen_random_uuid(),
  sender_id     uuid references profiles (id) on delete set null,
  recipient_ids uuid[] not null,
  title         text not null,
  body          text not null,
  image_url     text not null default '',
  initial_page  text not null default '',
  parameter_data jsonb not null default '{}',
  status        text not null default 'queued', -- queued | sent | failed
  num_sent      int not null default 0,
  error         text,
  created_at    timestamptz not null default now(),
  processed_at  timestamptz
);
create index push_queue_pending_idx on push_queue (created_at) where status = 'queued';

-- ============================================================================
-- Triggers
-- ============================================================================

-- Auto-create profile rows when an auth user is created (incl. Firebase import)
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into profiles (id, display_name, photo_url)
  values (new.id,
          coalesce(new.raw_user_meta_data ->> 'full_name', ''),
          coalesce(new.raw_user_meta_data ->> 'avatar_url', ''))
  on conflict (id) do nothing;
  insert into profile_private (id, email)
  values (new.id, coalesce(new.email, ''))
  on conflict (id) do nothing;
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- Denormalized counters
create or replace function bump_post_like_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update posts set like_count = like_count + 1 where id = new.post_id;
  else
    update posts set like_count = greatest(like_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
create trigger post_likes_count
  after insert or delete on post_likes
  for each row execute function bump_post_like_count();

create or replace function bump_post_comment_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update posts set comment_count = comment_count + 1 where id = new.post_id;
  else
    update posts set comment_count = greatest(comment_count - 1, 0) where id = old.post_id;
  end if;
  return null;
end;
$$;
create trigger comments_count
  after insert or delete on comments
  for each row execute function bump_post_comment_count();

create or replace function bump_training_like_count()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    update user_trainings set like_count = like_count + 1 where id = new.training_id;
  else
    update user_trainings set like_count = greatest(like_count - 1, 0) where id = old.training_id;
  end if;
  return null;
end;
$$;
create trigger training_likes_count
  after insert or delete on training_likes
  for each row execute function bump_training_like_count();

-- Keep chats.last_message denormalized (was written client-side in Firestore)
create or replace function update_chat_last_message()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  update chats
     set last_message = coalesce(nullif(new.text, ''),
                                 case when new.video_url <> '' then 'Video'
                                      when new.image_url <> '' then 'Photo'
                                      else '' end),
         last_message_at = new.created_at,
         last_message_sent_by = new.user_id
   where id = new.chat_id;
  return null;
end;
$$;
create trigger chat_messages_last_message
  after insert on chat_messages
  for each row execute function update_chat_last_message();

-- ============================================================================
-- Row Level Security
-- ============================================================================
alter table profiles              enable row level security;
alter table profile_private       enable row level security;
alter table media_assets          enable row level security;
alter table posts                 enable row level security;
alter table post_likes            enable row level security;
alter table post_tags             enable row level security;
alter table comments              enable row level security;
alter table comment_likes         enable row level security;
alter table stories               enable row level security;
alter table story_views           enable row level security;
alter table follows               enable row level security;
alter table user_blocks           enable row level security;
alter table bookmarks             enable row level security;
alter table chats                 enable row level security;
alter table chat_members          enable row level security;
alter table chat_messages         enable row level security;
alter table notifications         enable row level security;
alter table recent_searches       enable row level security;
alter table workout_entries       enable row level security;
alter table exercise_sessions     enable row level security;
alter table user_trainings        enable row level security;
alter table training_participants enable row level security;
alter table training_likes        enable row level security;
alter table meal_scans            enable row level security;
alter table reports               enable row level security;
alter table administrative        enable row level security;
alter table verification_dash     enable row level security;
alter table fcm_tokens            enable row level security;
alter table push_queue            enable row level security;

-- Membership helper used by chat policies (security definer avoids RLS
-- recursion between chats / chat_members / chat_messages)
create or replace function is_chat_member(p_chat_id uuid)
returns boolean
language sql
security definer set search_path = public
stable
as $$
  select exists (
    select 1 from chat_members
    where chat_id = p_chat_id and user_id = auth.uid()
  );
$$;

-- profiles: public read (social app), owner writes
create policy "profiles are readable by everyone"
  on profiles for select using (true);
create policy "users update own profile"
  on profiles for update using (auth.uid() = id);

-- profile_private: strictly owner-only (PII + health data)
create policy "own private profile read"
  on profile_private for select using (auth.uid() = id);
create policy "own private profile update"
  on profile_private for update using (auth.uid() = id);

-- media_assets
create policy "media readable by authenticated"
  on media_assets for select using (auth.role() = 'authenticated');
create policy "own media insert"
  on media_assets for insert with check (auth.uid() = owner_id);
create policy "own media update"
  on media_assets for update using (auth.uid() = owner_id);
create policy "own media delete"
  on media_assets for delete using (auth.uid() = owner_id);

-- posts: read for signed-in users, write only your own
-- (fixes Firestore rule that let any user edit anyone's post)
create policy "posts readable by authenticated"
  on posts for select using (auth.role() = 'authenticated');
create policy "insert own posts"
  on posts for insert with check (auth.uid() = user_id);
create policy "update own posts"
  on posts for update using (auth.uid() = user_id);
create policy "delete own posts"
  on posts for delete using (auth.uid() = user_id);

create policy "likes readable" on post_likes for select using (auth.role() = 'authenticated');
create policy "like as self" on post_likes for insert with check (auth.uid() = user_id);
create policy "unlike as self" on post_likes for delete using (auth.uid() = user_id);

create policy "tags readable" on post_tags for select using (auth.role() = 'authenticated');
create policy "tag on own post"
  on post_tags for insert
  with check (exists (select 1 from posts where id = post_id and user_id = auth.uid()));
create policy "untag on own post or self"
  on post_tags for delete
  using (user_id = auth.uid()
         or exists (select 1 from posts where id = post_id and user_id = auth.uid()));

create policy "comments readable" on comments for select using (auth.role() = 'authenticated');
create policy "comment as self" on comments for insert with check (auth.uid() = user_id);
create policy "edit own comment" on comments for update using (auth.uid() = user_id);
create policy "delete own comment or on own post"
  on comments for delete
  using (auth.uid() = user_id
         or exists (select 1 from posts where id = post_id and user_id = auth.uid()));

create policy "comment likes readable" on comment_likes for select using (auth.role() = 'authenticated');
create policy "comment like as self" on comment_likes for insert with check (auth.uid() = user_id);
create policy "comment unlike as self" on comment_likes for delete using (auth.uid() = user_id);

-- stories
create policy "stories readable" on stories for select using (auth.role() = 'authenticated');
create policy "insert own story" on stories for insert with check (auth.uid() = user_id);
create policy "delete own story" on stories for delete using (auth.uid() = user_id);
create policy "story views readable by story owner"
  on story_views for select
  using (exists (select 1 from stories where id = story_id and user_id = auth.uid()));
create policy "record own story view" on story_views for insert with check (auth.uid() = viewer_id);

-- follows / blocks
create policy "follows readable" on follows for select using (true);
create policy "follow as self" on follows for insert with check (auth.uid() = follower_id);
create policy "unfollow as self" on follows for delete using (auth.uid() = follower_id);
create policy "own blocks" on user_blocks for select using (auth.uid() = blocker_id);
create policy "block as self" on user_blocks for insert with check (auth.uid() = blocker_id);
create policy "unblock as self" on user_blocks for delete using (auth.uid() = blocker_id);

-- bookmarks: private to owner
create policy "own bookmarks read" on bookmarks for select using (auth.uid() = user_id);
create policy "own bookmarks insert" on bookmarks for insert with check (auth.uid() = user_id);
create policy "own bookmarks delete" on bookmarks for delete using (auth.uid() = user_id);

-- chats: members only (fixes "any signed-in user can read all DMs")
create policy "chats visible to members"
  on chats for select using (is_chat_member(id));
create policy "create chat"
  on chats for insert with check (auth.role() = 'authenticated');
create policy "members update chat"
  on chats for update using (is_chat_member(id));

create policy "see members of own chats"
  on chat_members for select using (is_chat_member(chat_id));
create policy "join or add to chat"
  on chat_members for insert
  with check (user_id = auth.uid() or is_chat_member(chat_id));
create policy "leave chat" on chat_members for delete using (user_id = auth.uid());

create policy "messages visible to members"
  on chat_messages for select using (is_chat_member(chat_id));
create policy "send message as self to own chat"
  on chat_messages for insert
  with check (auth.uid() = user_id and is_chat_member(chat_id));
create policy "delete own message"
  on chat_messages for delete using (auth.uid() = user_id);

-- notifications: actor creates, recipient reads/updates/deletes
create policy "own notifications read" on notifications for select using (auth.uid() = recipient_id);
create policy "notify as actor" on notifications for insert with check (auth.uid() = actor_id);
create policy "mark own notifications" on notifications for update using (auth.uid() = recipient_id);
create policy "clear own notifications" on notifications for delete using (auth.uid() = recipient_id);

-- recent searches: private
create policy "own searches" on recent_searches for select using (auth.uid() = owner_id);
create policy "own searches insert" on recent_searches for insert with check (auth.uid() = owner_id);
create policy "own searches update" on recent_searches for update using (auth.uid() = owner_id);
create policy "own searches delete" on recent_searches for delete using (auth.uid() = owner_id);

-- personal fitness data: private (was `create: if true` world-writable)
create policy "own workout entries" on workout_entries for select using (auth.uid() = user_id);
create policy "own workout insert" on workout_entries for insert with check (auth.uid() = user_id);
create policy "own workout update" on workout_entries for update using (auth.uid() = user_id);
create policy "own workout delete" on workout_entries for delete using (auth.uid() = user_id);

create policy "own exercise sessions" on exercise_sessions for select using (auth.uid() = user_id);
create policy "own exercise insert" on exercise_sessions for insert with check (auth.uid() = user_id);
create policy "own exercise update" on exercise_sessions for update using (auth.uid() = user_id);
create policy "own exercise delete" on exercise_sessions for delete using (auth.uid() = user_id);

-- group trainings: public within app, owner writes
create policy "trainings readable" on user_trainings for select using (auth.role() = 'authenticated');
create policy "create own training" on user_trainings for insert with check (auth.uid() = user_id);
create policy "update own training" on user_trainings for update using (auth.uid() = user_id);
create policy "delete own training" on user_trainings for delete using (auth.uid() = user_id);

create policy "participants readable" on training_participants for select using (auth.role() = 'authenticated');
create policy "join training as self" on training_participants for insert with check (auth.uid() = user_id);
create policy "leave training as self" on training_participants for delete using (auth.uid() = user_id);

create policy "training likes readable" on training_likes for select using (auth.role() = 'authenticated');
create policy "training like as self" on training_likes for insert with check (auth.uid() = user_id);
create policy "training unlike as self" on training_likes for delete using (auth.uid() = user_id);

-- meal scans: private
create policy "own meal scans" on meal_scans for select using (auth.uid() = user_id);
create policy "own meal scans insert" on meal_scans for insert with check (auth.uid() = user_id);
create policy "own meal scans update" on meal_scans for update using (auth.uid() = user_id);
create policy "own meal scans delete" on meal_scans for delete using (auth.uid() = user_id);

-- reports: users file them, only service_role reads (moderation dashboard)
create policy "file report as self"
  on reports for insert with check (auth.uid() = reporter_id);

-- administrative / verification_dash: service_role only — no client policies.
-- (was `allow write: if true` — world-writable — in Firestore)

-- fcm tokens: owner only
create policy "own tokens read" on fcm_tokens for select using (auth.uid() = user_id);
create policy "own tokens insert" on fcm_tokens for insert with check (auth.uid() = user_id);
create policy "own tokens delete" on fcm_tokens for delete using (auth.uid() = user_id);

-- push queue: clients enqueue only as themselves; worker (service_role) drains
create policy "enqueue push as self"
  on push_queue for insert with check (auth.uid() = sender_id);

-- ============================================================================
-- Realtime
-- ============================================================================
alter publication supabase_realtime add table chat_messages;
alter publication supabase_realtime add table chats;
alter publication supabase_realtime add table notifications;
alter publication supabase_realtime add table media_assets; -- upload status updates

-- ============================================================================
-- Feed RPC — hydrated home feed in one round-trip (replaces N+1 Firestore
-- reads: posts + author + like state). Keyset-paginated.
-- ============================================================================
create or replace function feed_page(
  p_before timestamptz default null,
  p_limit  int default 10
)
returns table (
  post_id uuid,
  created_at timestamptz,
  caption text,
  photo_url text,
  video_url text,
  video_thumbnail text,
  blurhash text,
  food_post boolean,
  like_count int,
  comment_count int,
  liked_by_me boolean,
  author_id uuid,
  author_username text,
  author_display_name text,
  author_photo_url text
)
language sql
security invoker
stable
as $$
  select p.id, p.created_at, p.caption,
         coalesce(ma_photo.storage_path, p.legacy_photo_url),
         coalesce(ma_video.thumbnail_url, p.legacy_video_url),
         p.video_thumbnail,
         coalesce(ma_photo.blurhash, ma_video.blurhash, ''),
         p.food_post, p.like_count, p.comment_count,
         exists (select 1 from post_likes pl
                 where pl.post_id = p.id and pl.user_id = auth.uid()),
         pr.id, pr.username, pr.display_name, pr.photo_url
    from posts p
    join profiles pr on pr.id = p.user_id
    left join media_assets ma_photo on ma_photo.id = p.photo_asset_id
    left join media_assets ma_video on ma_video.id = p.video_asset_id
   where not p.deleted
     and (p_before is null or p.created_at < p_before)
     and (p.user_id = auth.uid()
          or exists (select 1 from follows f
                     where f.follower_id = auth.uid()
                       and f.followee_id = p.user_id))
     and not exists (select 1 from user_blocks b
                     where (b.blocker_id = auth.uid() and b.blocked_id = p.user_id)
                        or (b.blocker_id = p.user_id and b.blocked_id = auth.uid()))
   order by p.created_at desc
   limit least(p_limit, 50);
$$;
