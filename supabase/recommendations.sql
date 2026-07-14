-- Global product recommendations shown on all pagpage screens.
-- Fill via Table Editor: recommendations (listing_id, sort_order, is_active).

CREATE TABLE IF NOT EXISTS public.recommendations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  sort_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT recommendations_listing_unique UNIQUE (listing_id)
);

CREATE INDEX IF NOT EXISTS recommendations_active_sort_idx
  ON public.recommendations(is_active, sort_order);

ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "recommendations_select_all" ON public.recommendations;

CREATE POLICY "recommendations_select_all"
  ON public.recommendations
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE OR REPLACE FUNCTION public.get_recommendations(p_exclude_listing_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  title text,
  description text,
  price double precision,
  img text,
  city text,
  category_name text,
  created_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH candidates AS (
    SELECT
      r.listing_id,
      r.sort_order,
      r.created_at AS linked_at
    FROM public.recommendations r
    WHERE r.is_active = true
    ORDER BY r.sort_order ASC, r.created_at DESC
    LIMIT 5
  )
  SELECT
    l.id,
    l.title,
    l.description,
    l.price,
    l.img,
    l.city,
    l.category_name,
    l.created_at
  FROM candidates c
  JOIN public.listings l ON l.id = c.listing_id
  WHERE p_exclude_listing_id IS NULL OR l.id <> p_exclude_listing_id
  ORDER BY c.sort_order ASC, c.linked_at DESC
  LIMIT 4;
$$;
