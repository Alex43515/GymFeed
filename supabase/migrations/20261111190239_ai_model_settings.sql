-- Each signed-in client can read the OpenAI model assigned to a feature.
-- Administrators can edit model in the Table Editor without a new app build.
create table public.ai_model_settings (
  feature text primary key check (feature in (
    'ai_coach', 'equipment_scan', 'body_scan', 'food_scan', 'starter_plan'
  )),
  model text not null default 'gpt-6-luna'
    check (model ~ '^[a-zA-Z0-9][a-zA-Z0-9._:-]{0,127}$')
);

alter table public.ai_model_settings enable row level security;
revoke all on public.ai_model_settings from public, anon, authenticated, service_role;
grant select on public.ai_model_settings to authenticated, service_role;
grant update (model) on public.ai_model_settings to service_role;

create policy "Signed-in users read AI model settings"
  on public.ai_model_settings for select to authenticated
  using (true);

insert into public.ai_model_settings (feature)
values ('ai_coach'), ('equipment_scan'), ('body_scan'), ('food_scan'), ('starter_plan');
