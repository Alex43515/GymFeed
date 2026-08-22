import 'dotenv/config';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

const checks = [
  [
    'meal_scans',
    'id,dish_name,description,calories,protein,carbs,fats,scanned_on,created_at',
  ],
  [
    'profile_private',
    'id,button_click,caloric_intake_per_day,protein_per_day,carbs_per_day,fats_per_day',
  ],
];

for (const [table, columns] of checks) {
  const { data, error } = await supabase.from(table).select(columns).limit(1);
  if (error) throw new Error(`${table}: ${error.message}`);
  console.log(`${table}: schema ready (${data.length} sample rows)`);
}
