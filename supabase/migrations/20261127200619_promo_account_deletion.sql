-- Account deletion must still work; the aggregate lifetime cap remains spent.
alter table promo_private.claims drop constraint claims_user_id_fkey;
alter table promo_private.claims add constraint claims_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete cascade;
