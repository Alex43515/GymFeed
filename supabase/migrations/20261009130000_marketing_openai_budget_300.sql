-- Raise the OpenAI monthly marketing allowance and keep the aggregate ceiling
-- large enough for every configured provider allowance.
with revised as (
  select
    month,
    jsonb_set(provider_limits, '{openai}', '300'::jsonb, true) as provider_limits
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
