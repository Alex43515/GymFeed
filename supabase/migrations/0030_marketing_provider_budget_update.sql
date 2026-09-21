-- Replace the retired Gemini/BytePlus/Blotato limits with the providers used by
-- the deployed marketing worker. The fal limit matches the prepaid test credit.
update public.marketing_budgets
set provider_limits = jsonb_build_object(
      'openai', 25,
      'fal', 25,
      'buffer', 18,
      'infrastructure', 10
    ),
    updated_at = now()
where month = date_trunc('month', now())::date;
