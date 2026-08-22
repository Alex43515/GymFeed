-- 0002_advisor_hardening.sql
-- Resolves the Supabase database advisors raised against 0001_initial_schema.
-- Three groups: (1) function/API surface hardening, (2) missing indexes + a
-- primary key, (3) per-row auth.* re-evaluation in RLS policies (the scale fix).

-- =====================================================================
-- 1. Function & API-surface hardening
-- =====================================================================

-- feed_page is the only function left with a role-mutable search_path.
alter function public.feed_page(timestamptz, int) set search_path = public;

-- Trigger-only functions must never be reachable as PostgREST RPCs. Trigger
-- execution does not consult the caller's EXECUTE grant, so revoking it is safe
-- and closes /rest/v1/rpc/<fn> for anon + authenticated.
revoke execute on function public.bump_post_comment_count()   from anon, authenticated;
revoke execute on function public.bump_post_like_count()      from anon, authenticated;
revoke execute on function public.bump_training_like_count()  from anon, authenticated;
revoke execute on function public.update_chat_last_message()  from anon, authenticated;
revoke execute on function public.handle_new_user()           from anon, authenticated;

-- is_chat_member is referenced inside RLS policies, so `authenticated` must keep
-- EXECUTE (policy expressions run as the querying role). anon is never a chat
-- member and has no policy that needs it — revoke there only.
revoke execute on function public.is_chat_member(uuid) from anon;

-- rls_auto_enable backs the `ensure_rls` event trigger (auto-enables RLS on any
-- new table). Keep the function; just take it off the public RPC surface.
revoke execute on function public.rls_auto_enable() from anon, authenticated;

-- =====================================================================
-- 2. Missing covering indexes for foreign keys + bookmarks primary key
-- =====================================================================

-- Every FK flagged by the linter as lacking a covering index. Needed so cascade
-- deletes and join filters don't seq-scan the child table.
create index if not exists ix_bookmarks_post_id                on public.bookmarks (post_id);
create index if not exists ix_bookmarks_training_id            on public.bookmarks (training_id);
create index if not exists ix_chat_messages_comment_id         on public.chat_messages (comment_id);
create index if not exists ix_chat_messages_post_id            on public.chat_messages (post_id);
create index if not exists ix_chat_messages_user_id            on public.chat_messages (user_id);
create index if not exists ix_chats_last_message_sent_by       on public.chats (last_message_sent_by);
create index if not exists ix_comment_likes_user_id            on public.comment_likes (user_id);
create index if not exists ix_comments_user_id                 on public.comments (user_id);
create index if not exists ix_notifications_actor_id           on public.notifications (actor_id);
create index if not exists ix_notifications_comment_id         on public.notifications (comment_id);
create index if not exists ix_notifications_post_id            on public.notifications (post_id);
create index if not exists ix_post_tags_user_id               on public.post_tags (user_id);
create index if not exists ix_posts_photo_asset_id            on public.posts (photo_asset_id);
create index if not exists ix_posts_video_asset_id            on public.posts (video_asset_id);
create index if not exists ix_push_queue_sender_id            on public.push_queue (sender_id);
create index if not exists ix_recent_searches_searched_user_id on public.recent_searches (searched_user_id);
create index if not exists ix_reports_reporter_id             on public.reports (reporter_id);
create index if not exists ix_stories_photo_asset_id          on public.stories (photo_asset_id);
create index if not exists ix_stories_video_asset_id          on public.stories (video_asset_id);
create index if not exists ix_story_views_viewer_id           on public.story_views (viewer_id);
create index if not exists ix_training_likes_user_id          on public.training_likes (user_id);
create index if not exists ix_user_blocks_blocked_id          on public.user_blocks (blocked_id);
create index if not exists ix_user_trainings_video_asset_id   on public.user_trainings (video_asset_id);

-- bookmarks had no primary key. Add a surrogate id, plus partial-unique indexes
-- that preserve the Firestore semantics (a user can bookmark a given item once
-- per kind). kind ∈ ('post','food_post','training'); post/food_post use post_id.
alter table public.bookmarks add column if not exists id uuid not null default gen_random_uuid();
alter table public.bookmarks add constraint bookmarks_pkey primary key (id);
create unique index if not exists bookmarks_uniq_post
  on public.bookmarks (user_id, kind, post_id)     where post_id is not null;
create unique index if not exists bookmarks_uniq_training
  on public.bookmarks (user_id, kind, training_id) where training_id is not null;

-- =====================================================================
-- 3. RLS init-plan optimisation
-- =====================================================================
-- Rewrite every public policy so auth.uid()/auth.role()/auth.jwt() is wrapped in
-- a scalar subquery. Postgres then evaluates it once per statement (an InitPlan)
-- instead of once per row — the difference between an index scan and a full scan
-- on large tables. Done generically so it stays correct as policies evolve; the
-- double-wrap guards keep it idempotent.
do $$
declare
  r record;
  q text;
  c text;
begin
  for r in
    select schemaname, tablename, policyname, qual, with_check
    from pg_policies
    where schemaname = 'public'
  loop
    q := r.qual;
    c := r.with_check;

    if q is not null then
      q := replace(q, 'auth.uid()',  '(select auth.uid())');
      q := replace(q, 'auth.role()', '(select auth.role())');
      q := replace(q, 'auth.jwt()',  '(select auth.jwt())');
      q := replace(q, '(select (select auth.uid()))',  '(select auth.uid())');
      q := replace(q, '(select (select auth.role()))', '(select auth.role())');
      q := replace(q, '(select (select auth.jwt()))',  '(select auth.jwt())');
    end if;

    if c is not null then
      c := replace(c, 'auth.uid()',  '(select auth.uid())');
      c := replace(c, 'auth.role()', '(select auth.role())');
      c := replace(c, 'auth.jwt()',  '(select auth.jwt())');
      c := replace(c, '(select (select auth.uid()))',  '(select auth.uid())');
      c := replace(c, '(select (select auth.role()))', '(select auth.role())');
      c := replace(c, '(select (select auth.jwt()))',  '(select auth.jwt())');
    end if;

    if q is distinct from r.qual or c is distinct from r.with_check then
      if q is not null and c is not null then
        execute format('alter policy %I on %I.%I using (%s) with check (%s)',
                       r.policyname, r.schemaname, r.tablename, q, c);
      elsif q is not null then
        execute format('alter policy %I on %I.%I using (%s)',
                       r.policyname, r.schemaname, r.tablename, q);
      elsif c is not null then
        execute format('alter policy %I on %I.%I with check (%s)',
                       r.policyname, r.schemaname, r.tablename, c);
      end if;
    end if;
  end loop;
end $$;
