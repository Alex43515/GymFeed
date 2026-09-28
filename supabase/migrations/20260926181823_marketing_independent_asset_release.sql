-- Final approval releases one asset, even when an older multi-item batch exists.
do $migration$
declare
  definition text;
  old_guard text := 'where i.locked_batch_id = v_batch.id and (c.status not in';
begin
  select pg_get_functiondef('public.marketing_campaign_command(text,jsonb)'::regprocedure) into definition;
  if strpos(definition, old_guard) = 0 then raise exception 'Expected publication guard was not found'; end if;
  definition := replace(definition, old_guard, 'where i.content_id = v_content_id and (c.status not in');
  definition := replace(definition, 'Every finished asset in this seven-day batch must be approved before Buffer scheduling',
    'This finished asset must be approved before Buffer scheduling');
  execute definition;
end;
$migration$;
