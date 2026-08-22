-- 0004_profile_parity_fields.sql
-- Adds the remaining per-user scalar fields the Flutter app reads off the old
-- Firestore `users` document, so the Supabase Profile model is a faithful drop-in.
-- These are private (personal fitness data, AI outputs, and client UI-state), so
-- they live on profile_private (owner-only via existing RLS), not public profiles.

alter table public.profile_private
  -- extra progress photos (1–3 already exist)
  add column if not exists progress_image4  text,
  add column if not exists progress_image5  text,
  add column if not exists progress_image6  text,
  add column if not exists progress_image12 text,
  add column if not exists progress_button_index int,
  -- a second birthday/date field the app carries as `age2`
  add column if not exists age2 date,
  -- AI raw outputs
  add column if not exists gemini_parse  text,
  add column if not exists gemini_parse2 text,
  add column if not exists gemini_parse3 text,
  -- body-composition string variants (doubles ufat2/bfat2/... already exist)
  add column if not exists ufat     text,
  add column if not exists bfat     text,
  add column if not exists leanmass text,
  add column if not exists efat     text,
  -- energy figures (kept as text to match the app's freeform AI strings)
  add column if not exists calories_burnt  text,
  add column if not exists calories_burn   text,
  add column if not exists calories_intake text,
  -- generated plans / coaching copy
  add column if not exists meal_plan    text,
  add column if not exists workout_plan text,
  add column if not exists pro_tips     text,
  add column if not exists quotes       text,
  -- macro targets
  add column if not exists carbs_per_day          text,
  add column if not exists protein_per_day        text,
  add column if not exists fats_per_day           text,
  add column if not exists caloric_intake_per_day text,
  -- onboarding extras
  add column if not exists gender2       text,
  add column if not exists workout_where text,
  add column if not exists food_alergies text,
  -- meal scanner description (numeric scanner cols already exist)
  add column if not exists description_scanner text,
  -- legacy compressed-video marker
  add column if not exists compress_video text,
  -- client-side "has loaded" UI flags the app persisted on the user doc
  add column if not exists is_loaded_home          int,
  add column if not exists is_loaded_training       int,
  add column if not exists is_loaded_profile        int,
  add column if not exists is_loaded_join_training  int,
  add column if not exists is_loaded_trainings      boolean;
