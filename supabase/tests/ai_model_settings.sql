-- Run against a disposable database with ai_model_settings migrated.
begin;

do $$
begin
  assert (select count(*) = 5 and bool_and(model = 'gpt-6-luna')
    from public.ai_model_settings), 'All five features must default to Luna';

  set local role anon;
  begin
    perform model from public.ai_model_settings;
    raise exception 'Signed-out clients can read settings';
  exception when insufficient_privilege then null;
  end;
  reset role;

  set local role authenticated;
  assert (select count(*) = 5 from public.ai_model_settings);
  begin
    update public.ai_model_settings set model = 'gpt-4o-mini' where feature = 'food_scan';
    raise exception 'Signed-in clients can change the model';
  exception when insufficient_privilege then null;
  end;
  reset role;

  set local role service_role;
  update public.ai_model_settings set model = 'gpt-5.4-mini' where feature = 'equipment_scan';
  begin
    update public.ai_model_settings set model = 'bad model' where feature = 'equipment_scan';
    raise exception 'Invalid model ID was accepted';
  exception when check_violation then null;
  end;
  reset role;

  set local role authenticated;
  assert (select model = 'gpt-5.4-mini' from public.ai_model_settings
    where feature = 'equipment_scan'), 'Client must see the updated assignment';
  assert (select count(*) = 4 from public.ai_model_settings
    where model = 'gpt-6-luna'), 'Editing one feature must preserve the others';
  reset role;
end;
$$;

rollback;
