-- Enforce terminal state immutability even for direct authenticated REST
-- updates, rather than relying only on the application's RPC call path.
alter policy "update own coach plan status" on public.ai_coach_plan_actions
  using ((select auth.uid()) = user_id and status = 'pending')
  with check ((select auth.uid()) = user_id and status <> 'pending');
