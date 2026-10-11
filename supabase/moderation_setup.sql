-- UGC moderation (App Store Guideline 1.2), adapted to the current database.
-- Combines ugc_moderation.sql + admin_content.sql + the guest-report part of
-- 20260916_app_store_prep.sql. Run after security_hardening.sql in
-- Supabase Studio -> SQL Editor. Safe to re-run.
--
-- Flow:
--   * Anyone can report a listing (guests get a forced anon_ reporter id).
--   * 3 reports from different logged-in users hide the listing
--     (moderation_status = 'under_review'); guest reports only go to the queue,
--     so one guest cannot hide a listing by reporting it three times.
--   * Hidden listings stay visible to their author only.
--   * Admin reviews public.moderation_queue and calls
--     admin_review_listing(id, 'active' | 'removed', reason) as service_role
--     (or from the SQL Editor).
--   * Logged-in users can block other users (app filters them out).

BEGIN;

-- 1. listings: moderation columns ---------------------------------------------
ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS moderation_status text NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS report_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS moderated_at timestamptz,
  ADD COLUMN IF NOT EXISTS moderation_reason text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'listings_moderation_status_check'
      AND conrelid = 'public.listings'::regclass
  ) THEN
    ALTER TABLE public.listings
      ADD CONSTRAINT listings_moderation_status_check
      CHECK (moderation_status IN ('active', 'under_review', 'removed'));
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS listings_moderation_status_idx
  ON public.listings (moderation_status);

-- 2. listing_reports / user_blocks tables ------------------------------------
CREATE TABLE IF NOT EXISTS public.listing_reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id text NOT NULL,
  reporter_id text NOT NULL,
  reason text NOT NULL,
  details text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.listing_reports
  ADD COLUMN IF NOT EXISTS details text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'listing_reports_reason_check'
      AND conrelid = 'public.listing_reports'::regclass
  ) THEN
    ALTER TABLE public.listing_reports
      ADD CONSTRAINT listing_reports_reason_check
      CHECK (reason IN ('spam', 'fraud', 'prohibited', 'offensive', 'other'));
  END IF;
END;
$$;

-- The app upserts on (listing_id, reporter_id); keep the newest duplicate.
DELETE FROM public.listing_reports a
USING public.listing_reports b
WHERE a.listing_id = b.listing_id
  AND a.reporter_id = b.reporter_id
  AND (a.created_at, a.id::text) < (b.created_at, b.id::text);

CREATE UNIQUE INDEX IF NOT EXISTS listing_reports_unique_reporter
  ON public.listing_reports (listing_id, reporter_id);
CREATE INDEX IF NOT EXISTS listing_reports_listing_id_idx
  ON public.listing_reports (listing_id);

CREATE TABLE IF NOT EXISTS public.user_blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id text NOT NULL,
  blocked_user_id text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_blocks_not_self CHECK (blocker_id <> blocked_user_id)
);

DELETE FROM public.user_blocks a
USING public.user_blocks b
WHERE a.blocker_id = b.blocker_id
  AND a.blocked_user_id = b.blocked_user_id
  AND a.id::text < b.id::text;

CREATE UNIQUE INDEX IF NOT EXISTS user_blocks_unique_pair
  ON public.user_blocks (blocker_id, blocked_user_id);
CREATE INDEX IF NOT EXISTS user_blocks_blocker_id_idx
  ON public.user_blocks (blocker_id);

-- 3. Policies ------------------------------------------------------------------
ALTER TABLE public.listing_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  p record;
BEGIN
  FOR p IN
    SELECT tablename, policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('listing_reports', 'user_blocks')
  LOOP
    EXECUTE format('DROP POLICY %I ON public.%I', p.policyname, p.tablename);
  END LOOP;
END;
$$;

-- Reports: guests and users may file; users see/update only their own.
CREATE POLICY "listing_reports_insert" ON public.listing_reports
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    (auth.role() = 'authenticated' AND reporter_id = auth.uid()::text)
    OR (auth.role() = 'anon' AND reporter_id LIKE 'anon\_%')
  );

CREATE POLICY "listing_reports_select_own" ON public.listing_reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid()::text);

CREATE POLICY "listing_reports_update_own" ON public.listing_reports
  FOR UPDATE TO authenticated
  USING (reporter_id = auth.uid()::text)
  WITH CHECK (reporter_id = auth.uid()::text);

-- Blocks: own rows only.
CREATE POLICY "user_blocks_insert_own" ON public.user_blocks
  FOR INSERT TO authenticated WITH CHECK (blocker_id = auth.uid()::text);
CREATE POLICY "user_blocks_select_own" ON public.user_blocks
  FOR SELECT TO authenticated USING (blocker_id = auth.uid()::text);
CREATE POLICY "user_blocks_update_own" ON public.user_blocks
  FOR UPDATE TO authenticated
  USING (blocker_id = auth.uid()::text)
  WITH CHECK (blocker_id = auth.uid()::text);
CREATE POLICY "user_blocks_delete_own" ON public.user_blocks
  FOR DELETE TO authenticated USING (blocker_id = auth.uid()::text);

-- PostgREST upsert = INSERT ... ON CONFLICT DO UPDATE, which needs UPDATE
-- privilege even when no conflict happens. Guests have no UPDATE policy, so
-- the conflict path stays denied by RLS.
REVOKE ALL ON public.listing_reports FROM anon;
-- SELECT privilege is needed by upsert; no SELECT policy for anon, so RLS
-- still hides every row from guests.
GRANT SELECT, INSERT, UPDATE (listing_id, reporter_id, reason, details)
  ON public.listing_reports TO anon;
GRANT SELECT, INSERT, UPDATE ON public.listing_reports TO authenticated;
REVOKE DELETE ON public.listing_reports FROM authenticated;

REVOKE ALL ON public.user_blocks FROM anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_blocks TO authenticated;

-- Hidden listings are visible to their author only.
DROP POLICY IF EXISTS "listings_moderation_visibility" ON public.listings;
CREATE POLICY "listings_moderation_visibility" ON public.listings
  AS RESTRICTIVE FOR SELECT TO anon, authenticated
  USING (moderation_status = 'active' OR user_id::text = auth.uid()::text);

-- 4. Triggers -------------------------------------------------------------------
-- Clients can never approve, unhide or fake report counters.
CREATE OR REPLACE FUNCTION public.protect_listing_moderation_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF pg_trigger_depth() = 1
     AND auth.role() IN ('anon', 'authenticated') THEN
    IF TG_OP = 'INSERT' THEN
      NEW.moderation_status := 'active';
      NEW.report_count := 0;
      NEW.moderated_at := NULL;
      NEW.moderation_reason := NULL;
    ELSE
      NEW.moderation_status := OLD.moderation_status;
      NEW.report_count := OLD.report_count;
      NEW.moderated_at := OLD.moderated_at;
      NEW.moderation_reason := OLD.moderation_reason;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_listing_moderation_fields_trigger ON public.listings;
CREATE TRIGGER protect_listing_moderation_fields_trigger
BEFORE INSERT OR UPDATE ON public.listings
FOR EACH ROW EXECUTE FUNCTION public.protect_listing_moderation_fields();

-- Reporter identity is set by the server, never trusted from the client.
-- SECURITY DEFINER: guests have no UPDATE right on listings, which the row
-- lock below would otherwise require.
CREATE OR REPLACE FUNCTION public.protect_listing_report_identity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM 1 FROM public.listings
  WHERE id::text = CASE WHEN TG_OP = 'INSERT' THEN NEW.listing_id ELSE OLD.listing_id END
  FOR UPDATE;

  IF TG_OP = 'INSERT' THEN
    IF auth.role() = 'authenticated' THEN
      NEW.reporter_id := auth.uid()::text;
    ELSIF auth.role() = 'anon' THEN
      NEW.reporter_id := 'anon_' || gen_random_uuid()::text;
    END IF;
    IF auth.role() IN ('anon', 'authenticated') THEN
      NEW.created_at := clock_timestamp();
    END IF;
  ELSIF auth.role() IN ('anon', 'authenticated') THEN
    NEW.listing_id := OLD.listing_id;
    NEW.reporter_id := OLD.reporter_id;
    NEW.created_at := OLD.created_at;
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION public.protect_listing_report_identity() OWNER TO postgres;

DROP TRIGGER IF EXISTS protect_listing_report_identity_trigger ON public.listing_reports;
CREATE TRIGGER protect_listing_report_identity_trigger
BEFORE INSERT OR UPDATE ON public.listing_reports
FOR EACH ROW EXECUTE FUNCTION public.protect_listing_report_identity();

-- Recount reports; 3 unreviewed reports from logged-in users hide the listing.
CREATE OR REPLACE FUNCTION public.refresh_listing_moderation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_listing_id text;
  last_moderated_at timestamptz;
  unique_report_count integer;
  unreviewed_user_reports integer;
BEGIN
  target_listing_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.listing_id ELSE NEW.listing_id END;

  SELECT moderated_at INTO last_moderated_at
  FROM public.listings
  WHERE id::text = target_listing_id
  FOR UPDATE;

  SELECT count(DISTINCT reporter_id)::integer INTO unique_report_count
  FROM public.listing_reports
  WHERE listing_id = target_listing_id;

  SELECT count(DISTINCT reporter_id)::integer INTO unreviewed_user_reports
  FROM public.listing_reports
  WHERE listing_id = target_listing_id
    AND reporter_id NOT LIKE 'anon\_%'
    AND reporter_id NOT LIKE 'guest\_%'
    AND (last_moderated_at IS NULL OR created_at > last_moderated_at);

  UPDATE public.listings
  SET
    report_count = unique_report_count,
    moderation_status = CASE
      WHEN unreviewed_user_reports >= 3 AND moderation_status = 'active'
        THEN 'under_review' ELSE moderation_status END,
    moderated_at = CASE
      WHEN unreviewed_user_reports >= 3 AND moderation_status = 'active'
        THEN NULL ELSE moderated_at END,
    moderation_reason = CASE
      WHEN unreviewed_user_reports >= 3 AND moderation_status = 'active'
        THEN NULL ELSE moderation_reason END
  WHERE id::text = target_listing_id;

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
ALTER FUNCTION public.refresh_listing_moderation() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.refresh_listing_moderation() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS refresh_listing_moderation_trigger ON public.listing_reports;
CREATE TRIGGER refresh_listing_moderation_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.listing_reports
FOR EACH ROW EXECUTE FUNCTION public.refresh_listing_moderation();

-- Backfill counters for reports filed before the trigger existed.
WITH totals AS (
  SELECT listing_id, count(DISTINCT reporter_id)::integer AS total
  FROM public.listing_reports GROUP BY listing_id
)
UPDATE public.listings l
SET report_count = totals.total
FROM totals
WHERE l.id::text = totals.listing_id;

-- 5. Admin tools ------------------------------------------------------------------
DROP VIEW IF EXISTS public.moderation_queue;
CREATE VIEW public.moderation_queue
WITH (security_invoker = true)
AS
SELECT
  listing.id AS listing_id,
  listing.title,
  listing.user_id,
  listing.moderation_status,
  listing.report_count,
  count(DISTINCT report.reporter_id) FILTER (
    WHERE listing.moderated_at IS NULL OR report.created_at > listing.moderated_at
  ) AS unreviewed_report_count,
  listing.moderated_at,
  listing.moderation_reason,
  listing.created_at AS listing_created_at,
  max(report.created_at) AS latest_report_at,
  jsonb_agg(
    jsonb_build_object(
      'report_id', report.id,
      'reporter_id', report.reporter_id,
      'reason', report.reason,
      'details', report.details,
      'created_at', report.created_at
    ) ORDER BY report.created_at DESC
  ) FILTER (WHERE report.id IS NOT NULL) AS reports
FROM public.listings AS listing
LEFT JOIN public.listing_reports AS report
  ON report.listing_id = listing.id::text
WHERE listing.moderation_status <> 'active' OR listing.report_count > 0
GROUP BY listing.id, listing.title, listing.user_id, listing.moderation_status,
  listing.report_count, listing.moderated_at, listing.moderation_reason,
  listing.created_at;

REVOKE ALL ON public.moderation_queue FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.moderation_queue TO service_role;

CREATE OR REPLACE FUNCTION public.admin_review_listing(
  p_listing_id uuid,
  p_decision text,
  p_reason text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  affected_rows integer;
BEGIN
  IF p_decision NOT IN ('active', 'removed') THEN
    RAISE EXCEPTION 'Invalid moderation decision: %', p_decision;
  END IF;

  UPDATE public.listings
  SET moderation_status = p_decision,
      moderated_at = clock_timestamp(),
      moderation_reason = NULLIF(btrim(p_reason), '')
  WHERE id = p_listing_id;

  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  RETURN affected_rows = 1;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_review_listing(uuid, text, text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_review_listing(uuid, text, text) TO service_role;

-- 6. Search must respect RLS (so hidden listings never show up) -----------------
DO $$
DECLARE
  f regprocedure;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'search_listings'
  LOOP
    EXECUTE format('ALTER FUNCTION %s SECURITY INVOKER', f);
  END LOOP;
END;
$$;

COMMIT;

-- Admin cheat sheet (SQL Editor):
--   SELECT * FROM public.moderation_queue ORDER BY latest_report_at DESC NULLS LAST;
--   SELECT public.admin_review_listing('<listing uuid>', 'removed', 'Мошенничество');
--   SELECT public.admin_review_listing('<listing uuid>', 'active', 'Проверено');
