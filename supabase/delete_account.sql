-- Run in Supabase SQL Editor before App Store resubmission.
-- Enables in-app account deletion required by Apple Guideline 5.1.1(v).

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

  DELETE FROM public.device_tokens WHERE user_id = uid::text;
  DELETE FROM public.listings WHERE user_id = uid::text;
  DELETE FROM public.profiles WHERE id = uid::text;
  DELETE FROM public."user" WHERE id = uid::text;
  DELETE FROM auth.users WHERE id = uid;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
