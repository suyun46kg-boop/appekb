-- ============================================================================
-- Обновить только подкатегории Квартира (если полный скрипт уже запускали)
-- Supabase Dashboard -> SQL Editor -> Run
-- ============================================================================

update public.categories
set name = 'сдается квартира', parent_id1 = 3
where id1 = 301;

update public.categories
set name = 'квартира нужна', parent_id1 = 3
where id1 = 302;

insert into public.categories (name, id1, parent_id1)
select v.name, v.id1, v.parent_id1
from (values
  ('сдается квартира', 301, 3),
  ('квартира нужна', 302, 3)
) as v(name, id1, parent_id1)
where not exists (
  select 1 from public.categories c where c.id1 = v.id1
);

update public.listings
set category_id = 301, category_name = 'квартира · сдается квартира'
where category_id in (303, 305);

update public.listings
set category_id = 302, category_name = 'квартира · квартира нужна'
where category_id = 304;

delete from public.categories
where parent_id1 = 3 and id1 in (303, 304, 305);
