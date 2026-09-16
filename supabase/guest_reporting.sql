-- Run in Supabase SQL Editor after ugc_moderation.sql
-- Allows guest users (not logged in) to report listings.

DROP POLICY IF EXISTS "listing_reports_insert_anon" ON public.listing_reports;

CREATE POLICY "listing_reports_insert_anon"
  ON public.listing_reports
  FOR INSERT
  TO anon
  WITH CHECK (reporter_id LIKE 'anon_%');

GRANT INSERT ON public.listing_reports TO anon;
