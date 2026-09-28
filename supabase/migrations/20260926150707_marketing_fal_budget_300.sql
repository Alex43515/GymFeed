-- Raise the fal.ai monthly provider allowance and keep the aggregate monthly
-- ceiling large enough for all configured provider allowances.
with revised as (
  select
    month,
    jsonb_set(provider_limits, '{fal}', '300'::jsonb, true) as provider_limits
  from public.marketing_budgets
  where month = date_trunc('month', now())::date
)
update public.marketing_budgets as budget
set
  provider_limits = revised.provider_limits,
  total_limit = greatest(
    budget.total_limit,
    (select sum(value::numeric) from jsonb_each_text(revised.provider_limits))
  ),
  updated_at = now()
from revised
where budget.month = revised.month;
