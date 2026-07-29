-- UGC moderation for App Store Guideline 1.2
-- Run in Supabase SQL Editor before resubmission.

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

DROP POLICY IF EXISTS "listing_reports_insert_own" ON public.listing_reports;
DROP POLICY IF EXISTS "listing_reports_select_own" ON public.listing_reports;
DROP POLICY IF EXISTS "user_blocks_insert_own" ON public.user_blocks;
DROP POLICY IF EXISTS "user_blocks_select_own" ON public.user_blocks;
DROP POLICY IF EXISTS "user_blocks_delete_own" ON public.user_blocks;

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

-- Grant table access to authenticated role so PostgREST can route requests
GRANT SELECT, INSERT ON public.listing_reports TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.user_blocks TO authenticated;

-- Optional: stop storing passwords in public.user (auth is handled by Supabase Auth).
ALTER TABLE public."user" ALTER COLUMN pass DROP NOT NULL;
UPDATE public."user" SET pass = NULL WHERE pass IS NOT NULL;
