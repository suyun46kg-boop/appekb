-- UGC moderation for App Store Guideline 1.2
-- Run in Supabase SQL Editor before resubmission.

ALTER TABLE public.listings
  ADD COLUMN IF NOT EXISTS moderation_status text NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS report_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS moderated_at timestamptz,
  ADD COLUMN IF NOT EXISTS moderation_reason text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'listings_moderation_status_check'
      AND conrelid = 'public.listings'::regclass
  ) THEN
    ALTER TABLE public.listings
      ADD CONSTRAINT listings_moderation_status_check
      CHECK (moderation_status IN ('active', 'under_review', 'removed'));
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS listings_moderation_status_idx
  ON public.listings (moderation_status);

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

CREATE UNIQUE INDEX IF NOT EXISTS user_blocks_unique_pair
  ON public.user_blocks (blocker_id, blocked_user_id);

CREATE INDEX IF NOT EXISTS user_blocks_blocker_id_idx
  ON public.user_blocks (blocker_id);

ALTER TABLE public.listing_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "listing_reports_insert_own" ON public.listing_reports;
DROP POLICY IF EXISTS "listing_reports_select_own" ON public.listing_reports;
DROP POLICY IF EXISTS "listing_reports_update_own" ON public.listing_reports;
DROP POLICY IF EXISTS "user_blocks_insert_own" ON public.user_blocks;
DROP POLICY IF EXISTS "user_blocks_select_own" ON public.user_blocks;
DROP POLICY IF EXISTS "user_blocks_delete_own" ON public.user_blocks;
DROP POLICY IF EXISTS "listings_public_read" ON public.listings;
DROP POLICY IF EXISTS "listings_moderation_visibility" ON public.listings;

CREATE POLICY "listing_reports_insert_own"
  ON public.listing_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (reporter_id = auth.uid()::text);

CREATE POLICY "listing_reports_select_own"
  ON public.listing_reports
  FOR SELECT
  TO authenticated
  USING (reporter_id = auth.uid()::text);

CREATE POLICY "listing_reports_update_own"
  ON public.listing_reports
  FOR UPDATE
  TO authenticated
  USING (reporter_id = auth.uid()::text)
  WITH CHECK (reporter_id = auth.uid()::text);

CREATE POLICY "user_blocks_insert_own"
  ON public.user_blocks
  FOR INSERT
  TO authenticated
  WITH CHECK (blocker_id = auth.uid()::text);

CREATE POLICY "user_blocks_select_own"
  ON public.user_blocks
  FOR SELECT
  TO authenticated
  USING (blocker_id = auth.uid()::text);

CREATE POLICY "user_blocks_delete_own"
  ON public.user_blocks
  FOR DELETE
  TO authenticated
  USING (blocker_id = auth.uid()::text);

-- Marketplace listings are public, but moderated content is visible only to
-- its author. The restrictive policy is combined with all existing policies.
CREATE POLICY "listings_public_read"
  ON public.listings
  FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "listings_moderation_visibility"
  ON public.listings
  AS RESTRICTIVE
  FOR SELECT
  TO anon, authenticated
  USING (
    moderation_status = 'active'
    OR user_id::text = auth.uid()::text
  );

-- Grant table access to authenticated role so PostgREST can route requests
GRANT SELECT, INSERT, UPDATE ON public.listing_reports TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.user_blocks TO authenticated;

-- A client may edit its own listing, but it must never be able to approve or
-- unhide content. Nested updates from the trusted report trigger are allowed.
CREATE OR REPLACE FUNCTION public.protect_listing_moderation_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  request_role text := auth.role();
BEGIN
  IF pg_trigger_depth() = 1
     AND request_role IN ('anon', 'authenticated') THEN
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

DROP TRIGGER IF EXISTS protect_listing_moderation_fields_trigger
  ON public.listings;
CREATE TRIGGER protect_listing_moderation_fields_trigger
BEFORE INSERT OR UPDATE ON public.listings
FOR EACH ROW
EXECUTE FUNCTION public.protect_listing_moderation_fields();

-- Upsert may update the reason/details, but a reporter cannot move a report to
-- another listing or impersonate another user.
CREATE OR REPLACE FUNCTION public.protect_listing_report_identity()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  -- Take the same row lock used by administrator decisions before assigning
  -- the report timestamp. Whichever transaction wins the lock is ordered first.
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
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS protect_listing_report_identity_trigger
  ON public.listing_reports;
CREATE TRIGGER protect_listing_report_identity_trigger
BEFORE INSERT OR UPDATE ON public.listing_reports
FOR EACH ROW
EXECUTE FUNCTION public.protect_listing_report_identity();

-- Recount unique reports and hide content after the third report. Restoring or
-- removing content remains an explicit administrator decision.
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
  unreviewed_report_count integer;
BEGIN
  IF TG_OP = 'DELETE' THEN
    target_listing_id := OLD.listing_id;
  ELSE
    target_listing_id := NEW.listing_id;
  END IF;

  -- Serialize reports for the same listing so concurrent inserts cannot both
  -- observe a stale count and miss the threshold.
  SELECT moderated_at
    INTO last_moderated_at
  FROM public.listings
  WHERE id::text = target_listing_id
  FOR UPDATE;

  SELECT count(DISTINCT reporter_id)::integer
    INTO unique_report_count
  FROM public.listing_reports
  WHERE listing_id = target_listing_id;

  SELECT count(DISTINCT reporter_id)::integer
    INTO unreviewed_report_count
  FROM public.listing_reports
  WHERE listing_id = target_listing_id
    AND (
      last_moderated_at IS NULL
      OR created_at > last_moderated_at
    );

  UPDATE public.listings
  SET
    report_count = unique_report_count,
    moderation_status = CASE
      WHEN unreviewed_report_count >= 3 AND moderation_status = 'active'
        THEN 'under_review'
      ELSE moderation_status
    END,
    moderated_at = CASE
      WHEN unreviewed_report_count >= 3 AND moderation_status = 'active'
        THEN NULL
      ELSE moderated_at
    END,
    moderation_reason = CASE
      WHEN unreviewed_report_count >= 3 AND moderation_status = 'active'
        THEN NULL
      ELSE moderation_reason
    END
  WHERE id::text = target_listing_id;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS refresh_listing_moderation_trigger
  ON public.listing_reports;
CREATE TRIGGER refresh_listing_moderation_trigger
AFTER INSERT OR UPDATE OR DELETE ON public.listing_reports
FOR EACH ROW
EXECUTE FUNCTION public.refresh_listing_moderation();

-- Backfill reports that existed before this trigger was installed.
WITH report_totals AS (
  SELECT listing_id, count(DISTINCT reporter_id)::integer AS total
  FROM public.listing_reports
  GROUP BY listing_id
)
UPDATE public.listings AS listing
SET report_count = report_totals.total
FROM report_totals
WHERE listing.id::text = report_totals.listing_id;

UPDATE public.listings
SET
  moderation_status = 'under_review',
  moderated_at = NULL,
  moderation_reason = NULL
WHERE report_count >= 3
  AND moderation_status = 'active'
  AND moderated_at IS NULL;

-- RPC searches must execute as the caller so listings RLS cannot be bypassed.
DO $$
DECLARE
  search_function regprocedure;
BEGIN
  FOR search_function IN
    SELECT p.oid::regprocedure
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname = 'search_listings'
  LOOP
    EXECUTE format(
      'ALTER FUNCTION %s SECURITY INVOKER',
      search_function
    );
  END LOOP;
END
$$;

-- Optional: stop storing passwords in public.user (auth is handled by Supabase Auth).
ALTER TABLE public."user" ALTER COLUMN pass DROP NOT NULL;
UPDATE public."user" SET pass = NULL WHERE pass IS NOT NULL;
