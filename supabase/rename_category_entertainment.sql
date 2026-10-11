-- Переименование категории id1 = 13: «Билеты» -> «Развлечения».
-- Выполнить в Supabase Dashboard -> SQL Editor.

-- 1. Проверить, что это та самая строка (должно вернуться «Билеты» или похожее).
select id, id1, name, parent_id1 from public.categories where id1 = 13;

-- 2. Переименовать.
update public.categories
set name = 'Развлечения'
where id1 = 13;

-- 3. Проверить результат.
select id, id1, name, parent_id1 from public.categories where id1 = 13;
