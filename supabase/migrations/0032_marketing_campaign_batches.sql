-- Two independent approvals: a versioned idea, then its finished media.
-- All state mutations serialize on the campaign row. No enum changes and no
-- modifications to legacy campaign assets are performed by this migration.

create table if not exists public.marketing_campaigns (
  id uuid primary key default gen_random_uuid(),
  request_key text not null unique,
  name text not null,
  start_date date not null,
  days integer not null check (days between 1 and 31),
  timezone text not null,
  status text not null default 'planning' check (status in ('planning', 'idea_review', 'producing', 'complete')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.marketing_campaign_batches (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.marketing_campaigns(id) on delete restrict,
  batch_number integer not null check (batch_number > 0),
  request_key text not null,
  start_date date not null,
  end_date date not null check (end_date >= start_date and end_date - start_date < 7),
  status text not null default 'producing' check (status in ('producing', 'approved', 'scheduled')),
  manifest jsonb not null default '[]'::jsonb check (jsonb_typeof(manifest) = 'array'),
  created_at timestamptz not null default now(),
  unique (campaign_id, batch_number),
  unique (campaign_id, request_key)
);

create table if not exists public.marketing_campaign_ideas (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.marketing_campaigns(id) on delete restrict,
  content_id uuid not null unique references public.marketing_content(id) on delete restrict,
  publication_date date not null,
  format text not null check (format in ('video', 'instagram')),
  revision integer not null default 1 check (revision > 0),
  approved_revision integer,
  approved_plan_hash text,
  idea_status text not null default 'pending' check (idea_status in ('pending', 'approved', 'rejected', 'revising')),
  instructions text not null default '',
  reviewer text,
  approved_at timestamptz,
  revision_token uuid,
  revision_started_at timestamptz,
  revision_error text,
  revision_history jsonb not null default '[]'::jsonb,
  locked_batch_id uuid references public.marketing_campaign_batches(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (campaign_id, publication_date, format),
  check (approved_revision is null or approved_revision = revision),
  check (idea_status <> 'approved' or (approved_revision is not null and approved_plan_hash is not null and approved_at is not null))
);

create table if not exists public.marketing_campaign_decisions (
  id uuid primary key default gen_random_uuid(),
  campaign_id uuid not null references public.marketing_campaigns(id) on delete restrict,
  request_key text not null,
  payload_hash text not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  unique (campaign_id, request_key)
);

create table if not exists public.marketing_campaign_work (
  token uuid primary key default gen_random_uuid(),
  content_id uuid not null references public.marketing_content(id) on delete restrict,
  operation text not null,
  request_key text not null,
  state text not null default 'running' check (state in ('running', 'completed', 'failed', 'uncertain')),
  result jsonb not null default '{}'::jsonb,
  error text,
  started_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 minutes',
  completed_at timestamptz,
  unique (content_id, operation, request_key)
);
-- Expiration only identifies work needing operator reconciliation. It does not
-- authorize a duplicate charge or publication after a lost provider response.
create unique index if not exists marketing_campaign_work_active_idx
  on public.marketing_campaign_work(content_id) where state in ('running', 'uncertain');

create index if not exists marketing_campaign_ideas_state_idx
  on public.marketing_campaign_ideas(campaign_id, idea_status, publication_date);

alter table public.marketing_campaigns enable row level security;
alter table public.marketing_campaign_batches enable row level security;
alter table public.marketing_campaign_ideas enable row level security;
alter table public.marketing_campaign_decisions enable row level security;
alter table public.marketing_campaign_work enable row level security;
revoke all on table public.marketing_campaigns, public.marketing_campaign_batches,
  public.marketing_campaign_ideas, public.marketing_campaign_decisions, public.marketing_campaign_work from anon, authenticated;
grant all on table public.marketing_campaigns, public.marketing_campaign_batches,
  public.marketing_campaign_ideas, public.marketing_campaign_decisions, public.marketing_campaign_work to service_role;

create or replace function public.marketing_campaign_snapshot(p_campaign_id uuid)
returns jsonb language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'campaign', to_jsonb(c),
    'ideas', coalesce((select jsonb_agg(to_jsonb(i) || jsonb_build_object('content', to_jsonb(mc))
      order by i.publication_date, i.format)
      from public.marketing_campaign_ideas i join public.marketing_content mc on mc.id = i.content_id
      where i.campaign_id = c.id), '[]'::jsonb),
    'batches', coalesce((select jsonb_agg(to_jsonb(b) order by b.batch_number)
      from public.marketing_campaign_batches b where b.campaign_id = c.id), '[]'::jsonb)
  ) from public.marketing_campaigns c where c.id = p_campaign_id;
$$;

create or replace function public.marketing_campaign_command(p_action text, p_payload jsonb)
returns jsonb language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_campaign public.marketing_campaigns%rowtype;
  v_idea public.marketing_campaign_ideas%rowtype;
  v_content public.marketing_content%rowtype;
  v_batch public.marketing_campaign_batches%rowtype;
  v_previous public.marketing_campaign_batches%rowtype;
  v_event public.marketing_campaign_decisions%rowtype;
  v_work public.marketing_campaign_work%rowtype;
  v_campaign_id uuid;
  v_content_id uuid;
  v_date date;
  v_end date;
  v_count integer;
  v_video_count integer;
  v_ids uuid[];
  v_manifest jsonb;
  v_result jsonb;
  v_plan jsonb;
  v_key text;
  v_hash text;
  v_batch_number integer;
  v_token uuid;
begin
  if p_action not in ('create', 'status', 'register_day', 'submit', 'decide_idea',
    'claim_revision', 'finish_revision', 'fail_revision', 'start_batch', 'assert_generation', 'assert_publication',
    'acquire_work', 'finish_work') then
    raise exception 'Unknown campaign action';
  end if;
  if p_payload is null or jsonb_typeof(p_payload) <> 'object' then raise exception 'Campaign payload must be an object'; end if;

  if p_action = 'create' then
    if nullif(trim(p_payload->>'request_key'), '') is null or nullif(trim(p_payload->>'name'), '') is null
      or nullif(trim(p_payload->>'timezone'), '') is null then raise exception 'Campaign name, timezone and request key are required'; end if;
    if not exists (select 1 from pg_timezone_names where name = p_payload->>'timezone') then raise exception 'Invalid campaign timezone'; end if;
    if (p_payload->>'start_date') !~ '^\d{4}-\d{2}-\d{2}$' then raise exception 'Campaign start date must be YYYY-MM-DD'; end if;
    insert into public.marketing_campaigns(request_key, name, start_date, days, timezone)
      values (p_payload->>'request_key', p_payload->>'name', (p_payload->>'start_date')::date,
        (p_payload->>'days')::integer, p_payload->>'timezone') on conflict (request_key) do nothing;
    select * into strict v_campaign from public.marketing_campaigns where request_key = p_payload->>'request_key' for update;
    if v_campaign.name <> p_payload->>'name' or v_campaign.start_date <> (p_payload->>'start_date')::date
      or v_campaign.days <> (p_payload->>'days')::integer or v_campaign.timezone <> p_payload->>'timezone' then
      raise exception 'Campaign request key already belongs to a different plan';
    end if;
    return public.marketing_campaign_snapshot(v_campaign.id);
  end if;

  v_content_id := nullif(p_payload->>'content_id', '')::uuid;
  v_campaign_id := nullif(p_payload->>'campaign_id', '')::uuid;
  if p_action in ('assert_generation', 'assert_publication', 'acquire_work', 'finish_work') then
    select campaign_id into v_campaign_id from public.marketing_campaign_ideas where content_id = v_content_id;
    if v_campaign_id is null then raise exception 'Content is not in an approved campaign; legacy generation is blocked'; end if;
  end if;
  select * into v_campaign from public.marketing_campaigns where id = v_campaign_id for update;
  if not found then raise exception 'Campaign not found'; end if;
  if p_action = 'status' then return public.marketing_campaign_snapshot(v_campaign.id); end if;

  if p_action = 'register_day' then
    v_date := (p_payload->>'date')::date;
    if v_date < v_campaign.start_date or v_date >= v_campaign.start_date + v_campaign.days then
      raise exception 'Publication date is outside the campaign';
    end if;
    select array_agg(value::uuid) into v_ids from jsonb_array_elements_text(p_payload->'content_ids');
    if coalesce(array_length(v_ids, 1), 0) <> 2 or v_ids[1] = v_ids[2] then raise exception 'Exactly two distinct content IDs are required'; end if;
    -- A retry may inspect an already registered pair, but must not substitute IDs.
    if exists (select 1 from public.marketing_campaign_ideas where campaign_id = v_campaign.id and publication_date = v_date) then
      select count(*) into v_count from public.marketing_campaign_ideas
        where campaign_id = v_campaign.id and publication_date = v_date and content_id = any(v_ids);
      if v_count <> 2 then raise exception 'This campaign day already has different content IDs'; end if;
      return public.marketing_campaign_snapshot(v_campaign.id);
    end if;
    if v_campaign.status <> 'planning' then raise exception 'Campaign ideas are sealed'; end if;
    perform 1 from public.marketing_content where id = any(v_ids) for update;
    select count(*), count(*) filter (where content_type = 'video') into v_count, v_video_count
      from public.marketing_content where id = any(v_ids) and status = 'planned'
        and cardinality(asset_urls) = 0 and provider_task_id is null;
    if v_count <> 2 or v_video_count <> 1 then raise exception 'Each day requires one ungenerated video and one ungenerated carousel/image'; end if;
    if exists (select 1 from public.marketing_campaign_ideas where content_id = any(v_ids)) then raise exception 'Content belongs to another campaign day'; end if;
    insert into public.marketing_campaign_ideas(campaign_id, content_id, publication_date, format)
      select v_campaign.id, id, v_date, case when content_type = 'video' then 'video' else 'instagram' end
      from public.marketing_content where id = any(v_ids);
    update public.marketing_content set decision = decision || jsonb_build_object('campaign', jsonb_build_object(
      'id', v_campaign.id, 'date', v_date, 'timezone', v_campaign.timezone, 'idea_revision', 1, 'idea_status', 'pending',
      'approved_revision', null, 'batch_id', null, 'generation_authorized', false)), updated_at = now()
      where id = any(v_ids);

  elsif p_action = 'submit' then
    select count(*) into v_count from public.marketing_campaign_ideas where campaign_id = v_campaign.id;
    if v_count <> v_campaign.days * 2 then raise exception 'Every campaign day must contain both ideas before review'; end if;
    update public.marketing_campaigns set status = 'idea_review', updated_at = now()
      where id = v_campaign.id and status = 'planning';

  elsif p_action = 'start_batch' then
    v_key := nullif(trim(p_payload->>'request_key'), '');
    if v_key is null then raise exception 'An explicit batch request key is required'; end if;
    select * into v_batch from public.marketing_campaign_batches where campaign_id = v_campaign.id and request_key = v_key;
    if found then return jsonb_build_object('reused', true, 'batch', to_jsonb(v_batch), 'content_ids',
      (select jsonb_agg(entry->>'content_id') from jsonb_array_elements(v_batch.manifest) entry)); end if;
    if v_campaign.status = 'planning' then raise exception 'Submit all ideas for review first'; end if;
    select count(*) into v_count from public.marketing_campaign_ideas i join public.marketing_content c on c.id = i.content_id
      where i.campaign_id = v_campaign.id and i.idea_status = 'approved' and i.approved_revision = i.revision
        and i.approved_plan_hash = md5((c.decision->'content')::text);
    if v_count <> v_campaign.days * 2 then raise exception 'Every current campaign idea must be approved before media generation'; end if;
    select * into v_previous from public.marketing_campaign_batches where campaign_id = v_campaign.id order by batch_number desc limit 1;
    if found then
      if exists (select 1 from public.marketing_campaign_ideas i join public.marketing_content c on c.id = i.content_id
        where i.locked_batch_id = v_previous.id and (c.status not in ('approved', 'scheduled', 'published') or c.approved_at is null)) then
        raise exception 'The previous seven-day batch still needs finished-content approval';
      end if;
      update public.marketing_campaign_batches set status = 'approved' where id = v_previous.id and status = 'producing';
      v_date := v_previous.end_date + 1;
      v_batch_number := v_previous.batch_number + 1;
    else
      v_date := v_campaign.start_date;
      v_batch_number := 1;
    end if;
    if v_date >= v_campaign.start_date + v_campaign.days then
      update public.marketing_campaigns set status = 'complete', updated_at = now() where id = v_campaign.id;
      return jsonb_build_object('complete', true, 'content_ids', '[]'::jsonb, 'campaign_id', v_campaign.id);
    end if;
    v_end := least(v_date + 6, v_campaign.start_date + v_campaign.days - 1);
    select jsonb_agg(jsonb_build_object('content_id', i.content_id, 'idea_revision', i.revision,
      'date', i.publication_date, 'approved_plan_hash', i.approved_plan_hash) order by i.publication_date, i.format)
      into v_manifest from public.marketing_campaign_ideas i
      where i.campaign_id = v_campaign.id and i.publication_date between v_date and v_end and i.locked_batch_id is null;
    if coalesce(jsonb_array_length(v_manifest), 0) <> (v_end - v_date + 1) * 2 then raise exception 'Batch content manifest is incomplete'; end if;
    insert into public.marketing_campaign_batches(campaign_id, batch_number, request_key, start_date, end_date, manifest)
      values (v_campaign.id, v_batch_number, v_key, v_date, v_end, v_manifest) returning * into v_batch;
    update public.marketing_campaign_ideas set locked_batch_id = v_batch.id, updated_at = now()
      where campaign_id = v_campaign.id and publication_date between v_date and v_end;
    update public.marketing_content c set decision = jsonb_set(c.decision, '{campaign}',
      (c.decision->'campaign') || jsonb_build_object('batch_id', v_batch.id, 'generation_authorized', true)), updated_at = now()
      from public.marketing_campaign_ideas i where i.content_id = c.id and i.locked_batch_id = v_batch.id;
    update public.marketing_campaigns set status = 'producing', updated_at = now() where id = v_campaign.id;
    return jsonb_build_object('reused', false, 'batch', to_jsonb(v_batch), 'content_ids',
      (select jsonb_agg(entry->>'content_id') from jsonb_array_elements(v_manifest) entry));

  else
    select * into v_idea from public.marketing_campaign_ideas where campaign_id = v_campaign.id and content_id = v_content_id for update;
    if not found then raise exception 'Campaign idea not found'; end if;
    select * into strict v_content from public.marketing_content where id = v_content_id for update;

    if p_action = 'acquire_work' then
      if nullif(trim(p_payload->>'operation'), '') is null or nullif(trim(p_payload->>'request_key'), '') is null then
        raise exception 'Work operation and request key are required';
      end if;
      select * into v_work from public.marketing_campaign_work where content_id = v_content_id
        and operation = p_payload->>'operation' and request_key = p_payload->>'request_key';
      if found then
        return jsonb_build_object('acquired', false, 'reused', true, 'reason', v_work.state, 'result', v_work.result);
      end if;
      select * into v_work from public.marketing_campaign_work where content_id = v_content_id and state in ('running', 'uncertain');
      if found then
        return jsonb_build_object('acquired', false, 'reused', false, 'reason', 'work_needs_completion_or_reconciliation',
          'operation', v_work.operation, 'started_at', v_work.started_at, 'expires_at', v_work.expires_at);
      end if;
      -- Recheck inside this transaction, so approval cannot be revoked between
      -- an HTTP-level preflight check and acquiring the production claim.
      perform public.marketing_campaign_command(
        case when p_payload->>'operation' = 'publish' then 'assert_publication' else 'assert_generation' end,
        jsonb_build_object('content_id', v_content_id));
      insert into public.marketing_campaign_work(content_id, operation, request_key)
        values (v_content_id, p_payload->>'operation', p_payload->>'request_key') returning * into v_work;
      return jsonb_build_object('acquired', true, 'token', v_work.token, 'expires_at', v_work.expires_at);

    elsif p_action = 'finish_work' then
      select * into v_work from public.marketing_campaign_work where content_id = v_content_id and token = (p_payload->>'token')::uuid for update;
      if not found then raise exception 'Work claim not found'; end if;
      if p_payload->>'state' not in ('completed', 'failed', 'uncertain') then raise exception 'Invalid work state'; end if;
      if v_work.state in ('completed', 'failed') then
        if v_work.state <> p_payload->>'state' then raise exception 'Work claim is already finalized'; end if;
        return jsonb_build_object('reused', true, 'state', v_work.state, 'result', v_work.result);
      end if;
      update public.marketing_campaign_work set state = p_payload->>'state', result = coalesce(p_payload->'result', '{}'::jsonb),
        error = left(p_payload->>'error', 2000), completed_at = now() where token = v_work.token returning * into v_work;
      return jsonb_build_object('reused', false, 'state', v_work.state, 'result', v_work.result);

    elsif p_action in ('assert_generation', 'assert_publication') then
      if v_idea.idea_status <> 'approved' or v_idea.approved_revision is distinct from v_idea.revision
        or v_idea.approved_plan_hash is distinct from md5((v_content.decision->'content')::text) then
        raise exception 'This exact idea revision has not been approved';
      end if;
      if v_idea.locked_batch_id is null then raise exception 'This idea is not released in a seven-day batch'; end if;
      select * into strict v_batch from public.marketing_campaign_batches where id = v_idea.locked_batch_id;
      if not exists (select 1 from jsonb_array_elements(v_batch.manifest) entry where entry->>'content_id' = v_content_id::text
        and (entry->>'idea_revision')::integer = v_idea.revision and entry->>'approved_plan_hash' = v_idea.approved_plan_hash) then
        raise exception 'Content differs from the approved production manifest';
      end if;
      if p_action = 'assert_generation' and exists (
        select 1 from public.marketing_campaign_ideas i join public.marketing_content c on c.id = i.content_id
        where i.campaign_id = v_campaign.id and (i.idea_status <> 'approved' or i.approved_revision is distinct from i.revision
          or i.approved_plan_hash is distinct from md5((c.decision->'content')::text))) then
        raise exception 'Campaign has unapproved or changed ideas; generation is paused';
      end if;
      if p_action = 'assert_publication' and exists (
        select 1 from public.marketing_campaign_ideas i join public.marketing_content c on c.id = i.content_id
        where i.locked_batch_id = v_batch.id and (c.status not in ('approved', 'scheduled', 'published') or c.approved_at is null
          or i.idea_status <> 'approved' or i.approved_revision is distinct from i.revision
          or i.approved_plan_hash is distinct from md5((c.decision->'content')::text))) then
        raise exception 'Every finished asset in this seven-day batch must be approved before Buffer scheduling';
      end if;
      return jsonb_build_object('allowed', true, 'campaign_id', v_campaign.id, 'batch_id', v_batch.id,
        'content_id', v_content_id, 'idea_revision', v_idea.revision);

    elsif p_action = 'decide_idea' then
      v_key := nullif(trim(p_payload->>'request_key'), '');
      if v_key is null then raise exception 'A decision request key is required'; end if;
      v_hash := md5(p_payload::text);
      select * into v_event from public.marketing_campaign_decisions where campaign_id = v_campaign.id and request_key = v_key;
      if found then
        if v_event.payload_hash <> v_hash then raise exception 'Decision request key already used for a different decision'; end if;
        return v_event.result || jsonb_build_object('reused', true);
      end if;
      if v_campaign.status = 'planning' then raise exception 'Submit complete campaign ideas before approval'; end if;
      if (p_payload->>'revision')::integer is distinct from v_idea.revision then raise exception 'Stale idea revision'; end if;
      if p_payload->>'decision' not in ('approve', 'reject') then raise exception 'Decision must be approve or reject'; end if;
      if v_idea.idea_status = 'revising' then raise exception 'Idea revision is in progress'; end if;
      if exists (select 1 from public.marketing_campaign_work where content_id = v_content_id and state in ('running', 'uncertain')) then
        raise exception 'Complete or reconcile active production work before changing its idea';
      end if;
      if v_content.status in ('approved', 'scheduled', 'published', 'generating') then
        raise exception 'Cannot change an idea while generating or after finished-content approval';
      end if;
      if p_payload->>'decision' = 'reject' and nullif(trim(p_payload->>'instructions'), '') is null then
        raise exception 'Reject requires revision instructions';
      end if;
      if p_payload->>'decision' = 'approve' and v_idea.idea_status = 'rejected' then
        raise exception 'Revise the rejected idea before approving its new version';
      end if;
      update public.marketing_campaign_ideas set
        idea_status = case when p_payload->>'decision' = 'approve' then 'approved' else 'rejected' end,
        approved_revision = case when p_payload->>'decision' = 'approve' then revision else null end,
        approved_plan_hash = case when p_payload->>'decision' = 'approve' then md5((v_content.decision->'content')::text) else null end,
        approved_at = case when p_payload->>'decision' = 'approve' then now() else null end,
        instructions = coalesce(p_payload->>'instructions', ''), reviewer = p_payload->>'reviewer', updated_at = now()
        where id = v_idea.id returning * into v_idea;
      update public.marketing_content set decision = jsonb_set(decision, '{campaign}',
        (decision->'campaign') || jsonb_build_object('idea_status', v_idea.idea_status, 'idea_revision', v_idea.revision,
          'approved_revision', v_idea.approved_revision, 'generation_authorized', v_idea.idea_status = 'approved' and v_idea.locked_batch_id is not null)),
        updated_at = now() where id = v_content_id;
      if v_idea.locked_batch_id is not null and v_idea.idea_status = 'approved' then
        update public.marketing_campaign_batches set manifest = (select jsonb_agg(case when entry->>'content_id' = v_content_id::text
          then entry || jsonb_build_object('idea_revision', v_idea.revision, 'approved_plan_hash', v_idea.approved_plan_hash) else entry end)
          from jsonb_array_elements(manifest) entry) where id = v_idea.locked_batch_id;
      end if;
      v_result := jsonb_build_object('campaign_id', v_campaign.id, 'content_id', v_content_id,
        'revision', v_idea.revision, 'idea_status', v_idea.idea_status, 'reused', false);
      insert into public.marketing_campaign_decisions(campaign_id, request_key, payload_hash, result)
        values (v_campaign.id, v_key, v_hash, v_result);
      return v_result;

    elsif p_action = 'claim_revision' then
      if (p_payload->>'revision')::integer is distinct from v_idea.revision then raise exception 'Stale idea revision'; end if;
      if v_idea.idea_status = 'revising' then return jsonb_build_object('claimed', false, 'reason', 'revision_in_progress'); end if;
      if v_idea.idea_status <> 'rejected' or trim(v_idea.instructions) = '' then raise exception 'Only a rejected idea with instructions can be revised'; end if;
      v_token := gen_random_uuid();
      update public.marketing_campaign_ideas set idea_status = 'revising', revision_token = v_token,
        revision_started_at = now(), revision_error = null, updated_at = now() where id = v_idea.id;
      update public.marketing_content set decision = jsonb_set(decision, '{campaign,idea_status}', '"revising"'::jsonb), updated_at = now() where id = v_content_id;
      return jsonb_build_object('claimed', true, 'token', v_token, 'content', to_jsonb(v_content), 'instructions', v_idea.instructions);

    elsif p_action in ('finish_revision', 'fail_revision') then
      if v_idea.idea_status <> 'revising' or (p_payload->>'revision')::integer is distinct from v_idea.revision
        or (p_payload->>'token')::uuid is distinct from v_idea.revision_token then raise exception 'Revision claim is stale or invalid'; end if;
      if p_action = 'fail_revision' then
        update public.marketing_campaign_ideas set idea_status = 'rejected', revision_token = null,
          revision_error = left(p_payload->>'error', 2000), updated_at = now() where id = v_idea.id;
        update public.marketing_content set decision = jsonb_set(decision, '{campaign,idea_status}', '"rejected"'::jsonb), updated_at = now() where id = v_content_id;
      else
        v_plan := p_payload->'plan';
        if jsonb_typeof(v_plan) <> 'object' or nullif(trim(v_plan->>'topic'), '') is null
          or nullif(trim(v_plan->>'concept'), '') is null or nullif(trim(v_plan->>'hook'), '') is null then
          raise exception 'Revised plan requires topic, concept and hook';
        end if;
        update public.marketing_campaign_ideas set revision_history = revision_history || jsonb_build_array(jsonb_build_object(
          'revision', revision, 'instructions', instructions, 'previous_plan', v_content.decision->'content',
          'revised_at', now(), 'metadata', coalesce(p_payload->'metadata', '{}'::jsonb))),
          revision = revision + 1, idea_status = 'pending', approved_revision = null, approved_plan_hash = null,
          approved_at = null, revision_token = null, revision_error = null, updated_at = now()
          where id = v_idea.id returning * into v_idea;
        update public.marketing_content set status = 'planned', topic = v_plan->>'topic', concept = v_plan->>'concept', hook = v_plan->>'hook',
          decision = decision || jsonb_build_object('content', v_plan, 'generation', '{}'::jsonb,
            'review_revision', coalesce((decision->>'review_revision')::integer, 1) + 1,
            'review_instructions', v_idea.instructions,
            'review_history', coalesce(decision->'review_history', '[]'::jsonb) || jsonb_build_array(jsonb_build_object(
              'revision', coalesce((decision->>'review_revision')::integer, 1), 'idea_revision', v_idea.revision - 1,
              'instructions', v_idea.instructions, 'asset_urls', asset_urls, 'qa', qa, 'rejected_at', now())),
            'campaign', (decision->'campaign') || jsonb_build_object('idea_revision', v_idea.revision,
              'idea_status', 'pending', 'approved_revision', null, 'generation_authorized', false)),
          provider = null, provider_task_id = null, asset_urls = '{}', thumbnail_url = null, qa_score = null, qa = '{}',
          failure_reason = null, approved_by = null, approved_at = null, scheduled_at = null, published_at = null, updated_at = now()
          where id = v_content_id;
      end if;
    end if;
  end if;
  return public.marketing_campaign_snapshot(v_campaign.id);
end;
$$;

revoke all on function public.marketing_campaign_snapshot(uuid) from public, anon, authenticated;
revoke all on function public.marketing_campaign_command(text, jsonb) from public, anon, authenticated;
grant execute on function public.marketing_campaign_snapshot(uuid) to service_role;
grant execute on function public.marketing_campaign_command(text, jsonb) to service_role;
