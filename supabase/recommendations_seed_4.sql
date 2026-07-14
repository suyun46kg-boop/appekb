-- Seed 5 global recommendations so 4 cards stay visible after excluding
-- the currently opened product. Run in Supabase SQL Editor.

DELETE FROM public.recommendations;

INSERT INTO public.recommendations (listing_id, sort_order, is_active)
SELECT id, row_number, true
FROM (
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY created_at DESC) AS row_number
  FROM public.listings
  ORDER BY created_at DESC
  LIMIT 5
) picked;

-- Verify (should return up to 4 rows for any open product):
-- SELECT * FROM public.get_recommendations('UUID_ОТКРЫТОГО_ТОВАРА');
