-- ============================================================================
-- Подкатегории для Авто (1), Работа (2), Квартира (3)
-- Запустить в Supabase Dashboard -> SQL Editor -> Run
-- ============================================================================

-- 1. Колонка родителя (null = корневая категория)
alter table public.categories
  add column if not exists parent_id1 int null;

create index if not exists idx_categories_parent_id1
  on public.categories (parent_id1);

-- 2. Подкатегории Авто (parent = 1)
insert into public.categories (name, id1, parent_id1)
select v.name, v.id1, v.parent_id1
from (values
  ('Легковые', 101, 1),
  ('Грузовые', 102, 1),
  ('Мото', 103, 1),
  ('Запчасти', 104, 1),
  ('Аренда авто', 105, 1)
) as v(name, id1, parent_id1)
where not exists (
  select 1 from public.categories c where c.id1 = v.id1
);

-- 3. Подкатегории Работа (parent = 2)
insert into public.categories (name, id1, parent_id1)
select v.name, v.id1, v.parent_id1
from (values
  ('Вакансии', 201, 2),
  ('Резюме', 202, 2)
) as v(name, id1, parent_id1)
where not exists (
  select 1 from public.categories c where c.id1 = v.id1
);

-- 4. Подкатегории Квартира (parent = 3)
-- Оставляем только: сдается квартира, квартира нужна
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

-- Старые подкатегории квартиры убираем; объявления переносим на ближайшие
update public.listings set category_id = 301, category_name = 'квартира · сдается квартира'
where category_id in (303, 305); -- Продам / Посуточно → сдается

update public.listings set category_id = 302, category_name = 'квартира · квартира нужна'
where category_id = 304; -- Куплю → нужна

delete from public.categories
where parent_id1 = 3 and id1 in (303, 304, 305);

