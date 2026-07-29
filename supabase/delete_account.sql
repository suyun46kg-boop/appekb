-- Run in Supabase SQL Editor
-- Apple Guideline 5.1.1(v) — in-app account deletion

DROP FUNCTION IF EXISTS public.delete_own_account();

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- listing_reports.reporter_id is text
  DELETE FROM public.listing_reports WHERE reporter_id = uid::text;
  -- user_blocks columns are text
  DELETE FROM public.user_blocks WHERE blocker_id = uid::text OR blocked_user_id = uid::text;
  -- Check actual column type: cast both sides to be safe
  DELETE FROM public.listings WHERE user_id::text = uid::text;
  DELETE FROM public."user" WHERE id::text = uid::text;
  -- auth.users.id is uuid
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

ALTER FUNCTION public.delete_own_account() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
