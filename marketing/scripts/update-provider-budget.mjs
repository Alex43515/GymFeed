import { createClient } from "@supabase/supabase-js";

const { SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY } = process.env;
if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required");
}

const month = `${new Date().toISOString().slice(0, 7)}-01`;
const falLimit = Number(process.argv[2] ?? process.env.FAL_MONTHLY_BUDGET_USD ?? 25);
if (!Number.isFinite(falLimit) || falLimit < 0) {
  throw new Error("fal.ai monthly budget must be a non-negative number");
}
const client = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const current = await client.from("marketing_budgets").select("provider_limits").eq("month", month).single();
if (current.error) throw new Error(`Load marketing provider budget: ${current.error.message}`);
const providerLimits = { ...(current.data.provider_limits ?? {}), fal: falLimit };
const { error } = await client.from("marketing_budgets").update({ provider_limits: providerLimits }).eq("month", month);
if (error) throw new Error(`Update marketing provider budget: ${error.message}`);
console.log(`Updated the ${month} fal.ai monthly budget limit to $${falLimit.toFixed(2)}.`);
