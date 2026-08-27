-- Moderation queue for Supabase Dashboard.
-- Run after supabase/ugc_moderation.sql.

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
    WHERE listing.moderated_at IS NULL
       OR report.created_at > listing.moderated_at
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
    )
    ORDER BY report.created_at DESC
  ) FILTER (WHERE report.id IS NOT NULL) AS reports
FROM public.listings AS listing
LEFT JOIN public.listing_reports AS report
  ON report.listing_id = listing.id::text
WHERE listing.moderation_status <> 'active'
   OR listing.report_count > 0
GROUP BY
  listing.id,
  listing.title,
  listing.user_id,
  listing.moderation_status,
  listing.report_count,
  listing.moderated_at,
  listing.moderation_reason,
  listing.created_at;

REVOKE ALL ON public.moderation_queue FROM PUBLIC;
REVOKE ALL ON public.moderation_queue FROM anon, authenticated;

-- Only trusted database/service roles can approve or softly remove content.
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
  SET
    moderation_status = p_decision,
    moderated_at = clock_timestamp(),
    moderation_reason = NULLIF(btrim(p_reason), '')
  WHERE id = p_listing_id;

  GET DIAGNOSTICS affected_rows = ROW_COUNT;
  RETURN affected_rows = 1;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_review_listing(uuid, text, text)
  FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_review_listing(uuid, text, text)
  FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.admin_review_listing(uuid, text, text)
  TO service_role;

-- Dashboard examples:
-- Review the queue:
--   SELECT * FROM public.moderation_queue
--   ORDER BY latest_report_at DESC NULLS LAST;
--
-- Approve / restore:
--   SELECT public.admin_review_listing(
--     'LISTING_UUID',
--     'active',
--     'Checked by moderator'
--   );
--
-- Soft-remove while keeping reports and audit history:
--   SELECT public.admin_review_listing(
--     'LISTING_UUID',
--     'removed',
--     'Prohibited content'
--   );
