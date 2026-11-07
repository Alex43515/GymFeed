-- Owner decision (2026-11-07): these existing accounts never get a Founding
-- number. Then number all remaining existing real users by signup date.
-- Applied in production on 2026-11-07: 7 members, #0001-#0007.

insert into public.founding_exclusions (user_id, reason)
select p.id, case p.username
  when 'yyyyyy' then 'Test account'
  when 'lexsamusthave' then 'Founder second account' end
from public.profiles p where p.username in ('yyyyyy', 'lexsamusthave')
on conflict (user_id) do nothing;

select public.founding_backfill_existing();
