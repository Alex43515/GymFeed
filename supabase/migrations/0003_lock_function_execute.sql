-- 0003_lock_function_execute.sql
-- 0002 revoked EXECUTE from anon/authenticated, but Postgres also grants EXECUTE
-- to PUBLIC by default, and anon/authenticated inherit that. Revoke the PUBLIC
-- grant so these SECURITY DEFINER functions leave the PostgREST RPC surface.

-- Trigger / event-trigger functions: never called directly. Trigger execution
-- does not consult EXECUTE grants, so removing PUBLIC breaks nothing.
revoke execute on function public.bump_post_comment_count()  from public;
revoke execute on function public.bump_post_like_count()     from public;
revoke execute on function public.bump_training_like_count() from public;
revoke execute on function public.update_chat_last_message() from public;
revoke execute on function public.handle_new_user()          from public;
revoke execute on function public.rls_auto_enable()          from public;

-- is_chat_member is evaluated inside RLS policies as the querying role, so
-- authenticated must retain EXECUTE. Drop the blanket PUBLIC grant (removing anon)
-- and grant only authenticated back.
revoke execute on function public.is_chat_member(uuid) from public;
grant  execute on function public.is_chat_member(uuid) to authenticated;
