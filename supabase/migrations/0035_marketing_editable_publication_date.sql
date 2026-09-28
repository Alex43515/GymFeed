-- Planned date is reviewer-owned until an approved idea enters production.
-- Update the idea and the content campaign metadata atomically so generation,
-- final approval and Buffer all use the same schedule source.

create or replace function public.marketing_campaign_reschedule_idea(p_payload jsonb)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_campaign public.marketing_campaigns%rowtype;
  v_idea public.marketing_campaign_ideas%rowtype;
  v_content public.marketing_content%rowtype;
  v_date date;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then
    raise exception 'Campaign reschedule payload must be an object';
  end if;
  if (p_payload->>'publication_date') !~ '^\d{4}-\d{2}-\d{2}$' then
    raise exception 'Planned date must be YYYY-MM-DD';
  end if;
  v_date := (p_payload->>'publication_date')::date;
  if v_date < current_date then raise exception 'Planned date cannot be in the past'; end if;

  select * into v_campaign from public.marketing_campaigns
    where id = (p_payload->>'campaign_id')::uuid for update;
  if not found then raise exception 'Campaign not found'; end if;

  select * into v_idea from public.marketing_campaign_ideas
    where campaign_id = v_campaign.id and content_id = (p_payload->>'content_id')::uuid for update;
  if not found then raise exception 'Campaign idea not found'; end if;
  if (p_payload->>'revision')::integer is distinct from v_idea.revision then
    raise exception 'Stale idea revision';
  end if;
  if v_idea.locked_batch_id is not null then
    raise exception 'Planned date is locked because production already started';
  end if;
  if v_idea.idea_status not in ('pending', 'approved') then
    raise exception 'Only a pending or blocked approved idea can change its planned date';
  end if;

  select * into strict v_content from public.marketing_content where id = v_idea.content_id for update;
  if v_content.status <> 'planned' then
    raise exception 'Planned date is locked after media generation starts';
  end if;
  if exists (select 1 from public.marketing_campaign_work
    where content_id = v_idea.content_id and state in ('running', 'uncertain')) then
    raise exception 'Complete or reconcile active production work before changing the planned date';
  end if;
  if exists (select 1 from public.marketing_campaign_ideas
    where campaign_id = v_campaign.id and publication_date = v_date
      and format = v_idea.format and id <> v_idea.id) then
    raise exception 'Another % item in this campaign already uses planned date %', v_idea.format, v_date;
  end if;

  update public.marketing_campaign_ideas
    set publication_date = v_date, updated_at = now()
    where id = v_idea.id returning * into v_idea;
  update public.marketing_content
    set decision = jsonb_set(
      decision,
      '{campaign}',
      coalesce(decision->'campaign', '{}'::jsonb) || jsonb_build_object('date', v_date),
      true
    ), updated_at = now()
    where id = v_content.id returning * into v_content;

  return jsonb_build_object(
    'campaign_id', v_campaign.id,
    'content_id', v_content.id,
    'revision', v_idea.revision,
    'publication_date', v_idea.publication_date
  );
end;
$$;

revoke all on function public.marketing_campaign_reschedule_idea(jsonb) from public, anon, authenticated;
grant execute on function public.marketing_campaign_reschedule_idea(jsonb) to service_role;

comment on function public.marketing_campaign_reschedule_idea(jsonb) is
  'Atomically applies the reviewer-owned planned date before approved campaign content starts production.';
