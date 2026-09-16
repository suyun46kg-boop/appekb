-- ============================================================================
-- Supabase Migration: 20260916_app_store_prep.sql
-- Description: App Store release preparation migration
--   1. delete_own_account() RPC for App Store Guideline 5.1.1(v)
--   2. public.listing_reports RLS & permissions for authenticated + guest reporting (Guideline 1.2)
--   3. public.app_config version guard (min_version <= '1.0.1') and iOS store URL setup
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. In-App Account Deletion RPC: delete_own_account()
-- Complies with Apple App Store Review Guideline 5.1.1(v)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  calling_uid uuid := auth.uid();
  uid_text text;
BEGIN
  -- Verify caller authentication
  IF calling_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated: cannot delete account without an active session'
      USING ERRCODE = '28000';
  END IF;

  uid_text := calling_uid::text;

  -- 1. Delete user listings from public.listings (cascading user-generated content)
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'listings'
  ) THEN
    DELETE FROM public.listings
    WHERE user_id::text = uid_text;
  END IF;

  -- 2. Delete user profile record from public.users and/or public."user"
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'users'
  ) THEN
    EXECUTE 'DELETE FROM public.users WHERE id::text = $1' USING uid_text;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user'
  ) THEN
    EXECUTE 'DELETE FROM public."user" WHERE id::text = $1' USING uid_text;
  END IF;

  -- 3. Cleanup dependent user moderation relations (reports, blocks) if tables exist
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'listing_reports'
  ) THEN
    EXECUTE 'DELETE FROM public.listing_reports WHERE reporter_id = $1' USING uid_text;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'user_blocks'
  ) THEN
    EXECUTE 'DELETE FROM public.user_blocks WHERE blocker_id = $1 OR blocked_user_id = $1' USING uid_text;
  END IF;

  -- 4. Cleanup device push notification tokens if table exists
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'device_tokens'
  ) THEN
    EXECUTE 'DELETE FROM public.device_tokens WHERE user_id = $1' USING calling_uid;
  END IF;

  -- 5. Delete authentication record from auth.users
  DELETE FROM auth.users
  WHERE id = calling_uid;
END;
$$;

-- Set ownership and permissions for delete_own_account
ALTER FUNCTION public.delete_own_account() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;

COMMENT ON FUNCTION public.delete_own_account() IS 
  'Self-service account deletion for authenticated users complying with Apple App Store Guideline 5.1.1(v). Cascades listings, profile data, reports, blocks, and auth account.';


-- ----------------------------------------------------------------------------
-- 2. UGC Moderation: public.listing_reports RLS & Permissions
-- Allows both authenticated users and guests (anon) to submit listing reports
-- Complies with Apple App Store Review Guideline 1.2 (User-Generated Content)
-- ----------------------------------------------------------------------------

-- Ensure listing_reports table exists
CREATE TABLE IF NOT EXISTS public.listing_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id text NOT NULL,
  reporter_id text NOT NULL,
  reason text NOT NULL,
  details text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT listing_reports_reason_check CHECK (
    reason IN ('spam', 'fraud', 'prohibited', 'offensive', 'other')
  )
);

-- Enable RLS
ALTER TABLE public.listing_reports ENABLE ROW LEVEL SECURITY;

-- Grant table privileges so PostgREST allows INSERT from both anon and authenticated roles
GRANT SELECT, INSERT, UPDATE ON public.listing_reports TO authenticated;
GRANT INSERT ON public.listing_reports TO anon;

-- Drop obsolete or restrictive insert policies
DROP POLICY IF EXISTS "listing_reports_insert_own" ON public.listing_reports;
DROP POLICY IF EXISTS "listing_reports_insert_public" ON public.listing_reports;
DROP POLICY IF EXISTS "listing_reports_insert" ON public.listing_reports;

-- Create unified insert policy for both authenticated and anon roles
CREATE POLICY "listing_reports_insert"
  ON public.listing_reports
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (
    -- Authenticated users must report under their own uid (preventing spoofing)
    (auth.role() = 'authenticated' AND (reporter_id = auth.uid()::text OR reporter_id IS NULL OR reporter_id = ''))
    OR
    -- Anonymous guests are allowed to insert reports
    (auth.role() = 'anon')
  );

-- Ensure select policy for authenticated users to view their own reports
DROP POLICY IF EXISTS "listing_reports_select_own" ON public.listing_reports;
CREATE POLICY "listing_reports_select_own"
  ON public.listing_reports
  FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid()::text);

-- Ensure trigger sets valid reporter_id and timestamp for both anon and authenticated
CREATE OR REPLACE FUNCTION public.protect_listing_report_identity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- Row-lock target listing to serialize concurrent reports
  PERFORM 1
  FROM public.listings
  WHERE id::text = CASE
    WHEN TG_OP = 'INSERT' THEN NEW.listing_id
    ELSE OLD.listing_id
  END
  FOR UPDATE;

  IF auth.role() = 'authenticated' AND TG_OP = 'INSERT' THEN
    NEW.reporter_id := auth.uid()::text;
    NEW.created_at := clock_timestamp();
  ELSIF auth.role() = 'authenticated' THEN
    NEW.listing_id := OLD.listing_id;
    NEW.reporter_id := OLD.reporter_id;
    NEW.created_at := OLD.created_at;
  ELSIF auth.role() = 'anon' AND TG_OP = 'INSERT' THEN
    -- For guest users, assign a non-empty reporter_id if not provided
    NEW.reporter_id := coalesce(nullif(NEW.reporter_id, ''), 'guest_' || gen_random_uuid()::text);
    NEW.created_at := clock_timestamp();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_listing_report_identity_trigger ON public.listing_reports;
CREATE TRIGGER protect_listing_report_identity_trigger
BEFORE INSERT OR UPDATE ON public.listing_reports
FOR EACH ROW
EXECUTE FUNCTION public.protect_listing_report_identity();


-- ----------------------------------------------------------------------------
-- 3. App Version Configuration: public.app_config
-- Ensures min_version <= '1.0.1' so App Store reviewers are never blocked
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.app_config (
  id text PRIMARY KEY DEFAULT 'default',
  min_version text NOT NULL DEFAULT '1.0.0',
  latest_version text NOT NULL DEFAULT '1.0.1',
  message_ru text NOT NULL DEFAULT 'Доступна новая версия приложения. Обновите для продолжения работы.',
  message_ky text NOT NULL DEFAULT 'Колдонмонун жаңы версиясы бар. Улантуу үчүн жаңыртыңыз.',
  android_url text NOT NULL DEFAULT 'https://play.google.com/store/apps/details?id=mycompany.ekbkyrgyzdar',
  ios_url text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Enable RLS and grant read access to everyone
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_config_public_read" ON public.app_config;
CREATE POLICY "app_config_public_read"
  ON public.app_config
  FOR SELECT
  TO anon, authenticated
  USING (true);

GRANT SELECT ON public.app_config TO anon, authenticated;

-- Insert default row or update existing row to ensure min_version <= '1.0.1'
INSERT INTO public.app_config (
  id,
  min_version,
  latest_version,
  message_ru,
  message_ky,
  android_url,
  ios_url,
  updated_at
)
VALUES (
  'default',
  '1.0.0',
  '1.0.1',
  'Доступна новая версия приложения. Обновите для продолжения работы.',
  'Колдонмонун жаңы версиясы бар. Улантуу үчүн жаңыртыңыз.',
  'https://play.google.com/store/apps/details?id=mycompany.ekbkyrgyzdar',
  '',
  now()
)
ON CONFLICT (id) DO UPDATE
SET
  -- CRITICAL: min_version must never exceed '1.0.1' during 1.0.1 review cycle.
  -- Setting to '1.0.0' allows both 1.0.0 and 1.0.1 clients to run without force-update dialogs.
  min_version = CASE
    WHEN public.app_config.min_version > '1.0.1' THEN '1.0.0'
    ELSE coalesce(public.app_config.min_version, '1.0.0')
  END,
  latest_version = CASE
    WHEN public.app_config.latest_version < '1.0.1' THEN '1.0.1'
    ELSE public.app_config.latest_version
  END,
  updated_at = now();

-- Verify state
DO $$
DECLARE
  v_min text;
BEGIN
  SELECT min_version INTO v_min FROM public.app_config WHERE id = 'default';
  IF v_min > '1.0.1' THEN
    RAISE EXCEPTION 'Assertion failed: app_config.min_version (%) is greater than 1.0.1', v_min;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- DOCUMENTATION: Setting ios_url after App Store approval/ID assignment
-- ----------------------------------------------------------------------------
-- When Apple creates your App record in App Store Connect, an Apple ID (e.g. 6742398412)
-- is generated. Set the ios_url field so that when future force/soft updates are triggered,
-- iOS users tapping "Update" are redirected directly to your App Store product page:
--
-- Example SQL to run once App Store URL / ID is known:
--   UPDATE public.app_config
--   SET ios_url = 'https://apps.apple.com/app/id<YOUR_APPLE_APP_ID>',
--       updated_at = now()
--   WHERE id = 'default';
--
-- Note: Leaving ios_url empty will disable the store redirect button for iOS or fallback gracefully.
-- ----------------------------------------------------------------------------
