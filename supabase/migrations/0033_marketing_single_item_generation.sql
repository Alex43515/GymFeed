-- Allow each approved idea to enter production independently. Finished media
-- still requires its separate Content Review approval before publication.

create or replace function public.marketing_campaign_start_item(p_payload jsonb)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_campaign public.marketing_campaigns%rowtype;
  v_idea public.marketing_campaign_ideas%rowtype;
  v_content public.marketing_content%rowtype;
  v_batch public.marketing_campaign_batches%rowtype;
  v_key text;
  v_manifest jsonb;
  v_batch_number integer;
begin
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then raise exception 'Campaign item payload must be an object'; end if;
  v_key := nullif(trim(p_payload->>'request_key'), '');
  if v_key is null then raise exception 'An explicit item request key is required'; end if;

  select * into v_campaign from public.marketing_campaigns where id = (p_payload->>'campaign_id')::uuid for update;
  if not found then raise exception 'Campaign not found'; end if;
  if v_campaign.status = 'planning' then raise exception 'Submit campaign ideas for review first'; end if;

  select * into v_batch from public.marketing_campaign_batches where campaign_id = v_campaign.id and request_key = v_key;
  if found then return jsonb_build_object('reused', true, 'batch', to_jsonb(v_batch), 'content_ids', jsonb_build_array(p_payload->>'content_id')); end if;

  select * into v_idea from public.marketing_campaign_ideas
    where campaign_id = v_campaign.id and content_id = (p_payload->>'content_id')::uuid for update;
  if not found then raise exception 'Campaign idea not found'; end if;
  select * into strict v_content from public.marketing_content where id = v_idea.content_id for update;
  if v_idea.idea_status <> 'approved' or v_idea.approved_revision is distinct from v_idea.revision
    or v_idea.approved_plan_hash is distinct from md5((v_content.decision->'content')::text) then
    raise exception 'This exact idea revision has not been approved';
  end if;
  if v_idea.locked_batch_id is not null then
    select * into strict v_batch from public.marketing_campaign_batches where id = v_idea.locked_batch_id;
    return jsonb_build_object('reused', true, 'batch', to_jsonb(v_batch), 'content_ids', jsonb_build_array(v_idea.content_id));
  end if;

  v_manifest := jsonb_build_array(jsonb_build_object(
    'content_id', v_idea.content_id, 'idea_revision', v_idea.revision,
    'date', v_idea.publication_date, 'approved_plan_hash', v_idea.approved_plan_hash));
  select coalesce(max(batch_number), 0) + 1 into v_batch_number
    from public.marketing_campaign_batches where campaign_id = v_campaign.id;
  insert into public.marketing_campaign_batches(campaign_id, batch_number, request_key, start_date, end_date, manifest)
    values (v_campaign.id, v_batch_number, v_key, v_idea.publication_date, v_idea.publication_date, v_manifest)
    returning * into v_batch;
  update public.marketing_campaign_ideas set locked_batch_id = v_batch.id, updated_at = now() where id = v_idea.id;
  update public.marketing_content set decision = jsonb_set(decision, '{campaign}',
    (decision->'campaign') || jsonb_build_object('batch_id', v_batch.id, 'generation_authorized', true)), updated_at = now()
    where id = v_idea.content_id;
  update public.marketing_campaigns set status = 'producing', updated_at = now() where id = v_campaign.id;
  return jsonb_build_object('reused', false, 'batch', to_jsonb(v_batch), 'content_ids', jsonb_build_array(v_idea.content_id));
end;
$$;

revoke all on function public.marketing_campaign_start_item(jsonb) from public, anon, authenticated;
grant execute on function public.marketing_campaign_start_item(jsonb) to service_role;

-- The singleton batch and exact approved-plan manifest are now the generation
-- boundary. Other pending ideas in the campaign no longer pause this item.
do $migration$
declare
  v_definition text;
  v_start_marker text := $marker$if p_action = 'assert_generation' and exists ($marker$;
  v_end_marker text := $marker$raise exception 'Campaign has unapproved or changed ideas; generation is paused';$marker$;
  v_start integer;
  v_end integer;
begin
  select pg_get_functiondef('public.marketing_campaign_command(text,jsonb)'::regprocedure) into v_definition;
  v_start := strpos(v_definition, v_start_marker);
  v_end := strpos(v_definition, v_end_marker);
  if v_start = 0 or v_end < v_start then raise exception 'Expected generation campaign-wide gate was not found'; end if;
  v_end := strpos(substr(v_definition, v_end + length(v_end_marker)), 'end if;') + v_end + length(v_end_marker) - 1;
  if v_end < v_start then raise exception 'Expected generation gate terminator was not found'; end if;
  execute left(v_definition, v_start - 1) || substr(v_definition, v_end + length('end if;'));
end;
$migration$;
