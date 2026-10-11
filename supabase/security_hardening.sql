-- Security hardening for the public schema and the images bucket.
-- Run in Supabase Studio -> SQL Editor (as postgres). Safe to re-run.
--
-- What the app needs (checked against lib/ and supabase/*.sql):
--   listings        read: everyone (active) / owner (own hidden); write: owner only
--   user            insert/read/update own row (registration, profile, seller name)
--   profiles        not used by the app -> own row only
--   categories, carusel, search_index, app_config, recommendations: read only
--   broadcasts      read for logged-in users; written only by send-broadcast (service_role)
--   device_tokens, listing_reports, user_blocks: keep the policies from
--                   push_notifications*.sql / ugc_moderation.sql / app_store_prep.sql
--   storage images  public read; upload by logged-in users; change/delete by owner
-- service_role and SECURITY DEFINER functions (moderation, delete_own_account)
-- bypass RLS and keep working.

BEGIN;

-- 1. RLS on every table in public, no TRUNCATE etc. for client roles -------
DO $$
DECLARE
  t record;
BEGIN
  FOR t IN
    SELECT c.relname FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p')
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.relname);
    EXECUTE format('REVOKE TRUNCATE, REFERENCES, TRIGGER ON public.%I FROM anon, authenticated', t.relname);
  END LOOP;
END;
$$;

-- 2. Drop "allow everything" write policies anywhere in public --------------
-- (legacy FlutterFlow-style policies: INSERT/UPDATE/DELETE/ALL with `true`)
DO $$
DECLARE
  p record;
BEGIN
  FOR p IN
    SELECT tablename, policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND (
        (cmd IN ('UPDATE', 'DELETE', 'ALL') AND coalesce(qual, 'true') = 'true')
        OR (cmd = 'INSERT' AND coalesce(with_check, 'true') = 'true')
        OR (cmd IN ('UPDATE', 'ALL') AND with_check = 'true')
      )
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, p.tablename);
  END LOOP;
END;
$$;

-- Helper: drop every policy on a table (used where we redefine all of them).
CREATE OR REPLACE FUNCTION pg_temp.drop_all_policies(tbl text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE
  p record;
BEGIN
  FOR p IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = tbl
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, tbl);
  END LOOP;
END;
$$;

-- 3. listings ----------------------------------------------------------------
SELECT pg_temp.drop_all_policies('listings');

CREATE POLICY "listings_public_read" ON public.listings
  FOR SELECT TO anon, authenticated USING (true);

-- Only if ugc_moderation.sql has been applied (adds moderation_status).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'listings'
      AND column_name = 'moderation_status'
  ) THEN
    CREATE POLICY "listings_moderation_visibility" ON public.listings
      AS RESTRICTIVE FOR SELECT TO anon, authenticated
      USING (moderation_status = 'active' OR user_id::text = auth.uid()::text);
  END IF;
END;
$$;

CREATE POLICY "listings_insert_own" ON public.listings
  FOR INSERT TO authenticated
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "listings_update_own" ON public.listings
  FOR UPDATE TO authenticated
  USING (user_id::text = auth.uid()::text)
  WITH CHECK (user_id::text = auth.uid()::text);

CREATE POLICY "listings_delete_own" ON public.listings
  FOR DELETE TO authenticated
  USING (user_id::text = auth.uid()::text);

REVOKE INSERT, UPDATE, DELETE ON public.listings FROM anon;
GRANT SELECT ON public.listings TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.listings TO authenticated;

-- 4. "user" (phone numbers, legacy password column) ------------------------
-- The listing page falls back to "user".name only when listings.user_name is
-- empty, so fill it in before hiding other users' rows.
UPDATE public.listings l
SET user_name = u.name
FROM public."user" u
WHERE u.id::text = l.user_id::text
  AND (l.user_name IS NULL OR btrim(l.user_name) = '')
  AND u.name IS NOT NULL AND btrim(u.name) <> '';

-- Passwords live in auth.users; never keep a copy here.
UPDATE public."user" SET pass = NULL WHERE pass IS NOT NULL;

SELECT pg_temp.drop_all_policies('user');

CREATE POLICY "user_select_own" ON public."user"
  FOR SELECT TO authenticated USING (id::text = auth.uid()::text);

CREATE POLICY "user_insert_own" ON public."user"
  FOR INSERT TO authenticated WITH CHECK (id::text = auth.uid()::text);

CREATE POLICY "user_update_own" ON public."user"
  FOR UPDATE TO authenticated
  USING (id::text = auth.uid()::text)
  WITH CHECK (id::text = auth.uid()::text);

REVOKE ALL ON public."user" FROM anon;
REVOKE DELETE ON public."user" FROM authenticated;
GRANT SELECT, INSERT, UPDATE ON public."user" TO authenticated;

-- 5. profiles (unused by the app) -------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.profiles') IS NOT NULL THEN
    PERFORM pg_temp.drop_all_policies('profiles');
    CREATE POLICY "profiles_select_own" ON public.profiles
      FOR SELECT TO authenticated USING (id::text = auth.uid()::text);
    CREATE POLICY "profiles_update_own" ON public.profiles
      FOR UPDATE TO authenticated
      USING (id::text = auth.uid()::text)
      WITH CHECK (id::text = auth.uid()::text);
    REVOKE ALL ON public.profiles FROM anon;
    REVOKE INSERT, DELETE ON public.profiles FROM authenticated;
  END IF;
END;
$$;

-- 6. Read-only reference tables ----------------------------------------------
DO $$
DECLARE
  tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY['categories', 'carusel', 'search_index', 'app_config', 'recommendations']
  LOOP
    -- search_index may be a view; views inherit the base table's RLS.
    IF EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = tbl AND c.relkind IN ('r', 'p')
    ) THEN
      PERFORM pg_temp.drop_all_policies(tbl);
      EXECUTE format(
        'CREATE POLICY %I ON public.%I FOR SELECT TO anon, authenticated USING (true)',
        tbl || '_public_read', tbl);
    END IF;
    IF to_regclass('public.' || tbl) IS NOT NULL THEN
      EXECUTE format('REVOKE INSERT, UPDATE, DELETE ON public.%I FROM anon, authenticated', tbl);
      EXECUTE format('GRANT SELECT ON public.%I TO anon, authenticated', tbl);
    END IF;
  END LOOP;
END;
$$;

-- 7. broadcasts: written only by the send-broadcast function (service_role) --
DO $$
BEGIN
  IF to_regclass('public.broadcasts') IS NOT NULL THEN
    PERFORM pg_temp.drop_all_policies('broadcasts');
    CREATE POLICY "broadcasts_select_authenticated" ON public.broadcasts
      FOR SELECT TO authenticated USING (true);
    REVOKE ALL ON public.broadcasts FROM anon;
    REVOKE INSERT, UPDATE, DELETE ON public.broadcasts FROM authenticated;
  END IF;
END;
$$;

-- 8. Private tables: no "everyone can read" policies ------------------------
DO $$
DECLARE
  p record;
BEGIN
  FOR p IN
    SELECT tablename, policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('device_tokens', 'listing_reports', 'user_blocks')
      AND cmd = 'SELECT'
      AND coalesce(qual, 'true') = 'true'
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, p.tablename);
  END LOOP;
END;
$$;
-- Guests upsert reports and push tokens; PostgREST upsert (ON CONFLICT DO
-- UPDATE) needs SELECT privilege. With no SELECT policy for anon, RLS still
-- hides every row, so nothing can be read.
REVOKE UPDATE, DELETE ON public.listing_reports FROM anon;
GRANT SELECT, INSERT ON public.listing_reports TO anon;
REVOKE DELETE ON public.device_tokens FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.device_tokens TO anon;
REVOKE ALL ON public.user_blocks FROM anon;

-- 9. Storage: images bucket -------------------------------------------------
DO $$
DECLARE
  p record;
BEGIN
  -- Drop open write policies on storage.objects.
  FOR p IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND cmd IN ('INSERT', 'UPDATE', 'DELETE', 'ALL')
  LOOP
    EXECUTE format('DROP POLICY %I ON storage.objects', p.policyname);
  END LOOP;

  CREATE POLICY "images_insert_authenticated" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'images');

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'storage' AND table_name = 'objects' AND column_name = 'owner_id'
  ) THEN
    CREATE POLICY "images_update_own" ON storage.objects
      FOR UPDATE TO authenticated
      USING (bucket_id = 'images' AND owner_id = auth.uid()::text)
      WITH CHECK (bucket_id = 'images' AND owner_id = auth.uid()::text);
    CREATE POLICY "images_delete_own" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'images' AND owner_id = auth.uid()::text);
  ELSE
    CREATE POLICY "images_update_own" ON storage.objects
      FOR UPDATE TO authenticated
      USING (bucket_id = 'images' AND owner = auth.uid())
      WITH CHECK (bucket_id = 'images' AND owner = auth.uid());
    CREATE POLICY "images_delete_own" ON storage.objects
      FOR DELETE TO authenticated
      USING (bucket_id = 'images' AND owner = auth.uid());
  END IF;
END;
$$;

COMMIT;

-- Check afterwards:
--   SELECT schemaname, tablename, policyname, cmd, roles, qual, with_check
--   FROM pg_policies WHERE schemaname IN ('public', 'storage')
--   ORDER BY 1, 2, 3;
