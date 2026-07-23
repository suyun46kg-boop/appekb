-- ============================================================================
-- Нечёткий поиск для страницы поиска (searchpage22)
-- Запустить один раз в Supabase Dashboard -> SQL Editor -> New query -> Run
-- ============================================================================

-- 1. Расширения: pg_trgm (похожесть/опечатки), unaccent (игнор диакритики)
create extension if not exists pg_trgm;
create extension if not exists unaccent;

-- 2. Индексы для быстрого поиска по подстроке и похожести
create index if not exists idx_listings_title_trgm
  on public.listings using gin (title gin_trgm_ops);
create index if not exists idx_listings_category_name_trgm
  on public.listings using gin (category_name gin_trgm_ops);
create index if not exists idx_listings_description_trgm
  on public.listings using gin (description gin_trgm_ops);

-- Индексы для фильтров и сортировки
create index if not exists idx_listings_price       on public.listings (price);
create index if not exists idx_listings_city        on public.listings (city);
create index if not exists idx_listings_category_id on public.listings (category_id);
create index if not exists idx_listings_created_at  on public.listings (created_at desc);

-- 3. Функция поиска: нечёткое совпадение + фильтры + сортировка + пагинация
create or replace function public.search_listings(
  search_text      text             default '',
  min_price        double precision default null,
  max_price        double precision default null,
  city_filter      text             default null,
  category_filter  int              default null,
  sort_option      text             default 'relevance', -- relevance | newest | price_asc | price_desc
  limit_count      int              default 20,
  offset_count     int              default 0
)
returns setof public.listings
language sql
stable
as $$
  select l.*
  from public.listings l
  where
    (
      search_text = '' or
      l.title         ilike '%' || search_text || '%' or
      l.category_name ilike '%' || search_text || '%' or
      l.description   ilike '%' || search_text || '%' or
      similarity(coalesce(l.title, ''),         search_text) > 0.2 or
      similarity(coalesce(l.category_name, ''), search_text) > 0.2
    )
    and (min_price is null or l.price >= min_price)
    and (max_price is null or l.price <= max_price)
    and (city_filter is null or l.city = city_filter)
    and (
      category_filter is null
      or l.category_id = category_filter
      or l.category_id in (
        select c.id1
        from public.categories c
        where c.parent_id1 = category_filter
      )
    )
  order by
    -- дешевле
    case when sort_option = 'price_asc'  then l.price end asc  nulls last,
    -- дороже
    case when sort_option = 'price_desc' then l.price end desc nulls last,
    -- по релевантности (только при непустом запросе)
    case
      when sort_option = 'relevance' and search_text <> ''
      then greatest(
             similarity(coalesce(l.title, ''),         search_text),
             similarity(coalesce(l.category_name, ''), search_text)
           )
    end desc nulls last,
    -- финальный тай-брейк: новые сверху
    l.created_at desc
  limit  limit_count
  offset offset_count;
$$;

-- 4. Разрешить вызов функции из приложения (anon / авторизованные)
grant execute on function public.search_listings(
  text, double precision, double precision, text, int, text, int, int
) to anon, authenticated;
