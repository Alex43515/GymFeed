-- Reconcile both interrupted active generation and intake rows that claimed to
-- start but never acquired a batch or provider task. The latter can occur when
-- concurrent item starts were incorrectly coalesced by the worker.

create or replace function public.marketing_reconcile_interrupted_generation(p_worker_started_at timestamptz)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_content_ids uuid[];
  v_campaign_ids uuid[];
  v_message text := 'Generation failed: the worker stopped or restarted before completion. Nothing is currently generating. Approve again only if you want a new attempt.';
begin
  if p_worker_started_at is null then raise exception 'Worker start time is required'; end if;

  select array_agg(c.id order by c.id),
         array_agg(distinct nullif(c.decision->'campaign'->>'id', '')::uuid)
           filter (where nullif(c.decision->'campaign'->>'id', '') is not null)
    into v_content_ids, v_campaign_ids
  from public.marketing_content c
  left join public.marketing_campaign_ideas idea on idea.content_id = c.id
  where c.decision->'workflow'->>'stage' = 'generating'
    and c.updated_at < p_worker_started_at
    and c.provider_task_id is null
    and coalesce(cardinality(c.asset_urls), 0) = 0
    and (
      c.status in ('planned', 'generating')
      or (c.status = 'failed' and c.failure_reason is null and idea.locked_batch_id is null)
    )
    and not exists (
      select 1 from public.marketing_campaign_work w
      where w.content_id = c.id and w.state = 'running' and w.started_at >= p_worker_started_at
    );

  if coalesce(cardinality(v_content_ids), 0) = 0 then
    return jsonb_build_object('content_ids', '[]'::jsonb, 'campaign_ids', '[]'::jsonb);
  end if;

  update public.marketing_campaign_work w
  set state = 'failed', error = v_message, completed_at = now()
  where w.content_id = any(v_content_ids) and w.state = 'running' and w.started_at < p_worker_started_at;

  update public.marketing_content c
  set status = 'failed',
      failure_reason = v_message,
      decision = jsonb_set(
        jsonb_set(
          c.decision,
          '{campaign}',
          coalesce(c.decision->'campaign', '{}'::jsonb) || jsonb_build_object(
            'idea_status', 'pending', 'approved_revision', null, 'generation_authorized', false
          ),
          true
        ),
        '{workflow}',
        coalesce(c.decision->'workflow', '{}'::jsonb) || jsonb_build_object(
          'stage', 'blocked', 'message', v_message, 'at', now(), 'interrupted', true
        ),
        true
      ),
      updated_at = now()
  where c.id = any(v_content_ids);

  update public.marketing_campaign_ideas idea
  set idea_status = 'pending', approved_revision = null, approved_plan_hash = null,
      approved_at = null, updated_at = now()
  where idea.content_id = any(v_content_ids) and idea.idea_status = 'approved';

  return jsonb_build_object('content_ids', to_jsonb(v_content_ids), 'campaign_ids', to_jsonb(v_campaign_ids));
end;
$$;

revoke all on function public.marketing_reconcile_interrupted_generation(timestamptz) from public, anon, authenticated;
grant execute on function public.marketing_reconcile_interrupted_generation(timestamptz) to service_role;
