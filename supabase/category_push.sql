-- Category push subscriptions.
-- Run in Supabase Studio -> SQL Editor after push_notifications.sql. Safe to re-run.
--
-- Flow:
--   * The app mirrors the user's chosen root categories into
--     device_tokens.category_ids (welcome, Profile -> Notifications, category bell).
--   * A new listing fires notify_new_listing_trigger, which calls the
--     notify-new-listing edge function via pg_net; it pushes only to devices
--     subscribed to that listing's root category (author excluded).
--   * Admin broadcasts go through send-broadcast: without category_id to
--     everyone, with category_id only to that category's subscribers.
--
-- After running, fill the settings once (values are never exposed to clients):
--   UPDATE private.push_settings
--   SET functions_url = 'https://ekbkyrgyz.site/functions/v1',
--       admin_key     = '<BROADCAST_ADMIN_KEY>'
--   WHERE id = 1;

BEGIN;

-- 1. Subscriptions on device tokens ------------------------------------------
ALTER TABLE public.device_tokens
  ADD COLUMN IF NOT EXISTS category_ids integer[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS device_tokens_category_ids_idx
  ON public.device_tokens USING gin (category_ids);

-- 2. Private settings for the trigger ------------------------------------------
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;

CREATE TABLE IF NOT EXISTS private.push_settings (
  id integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  functions_url text,
  admin_key text
);
INSERT INTO private.push_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
REVOKE ALL ON private.push_settings FROM PUBLIC, anon, authenticated;

-- 3. Trigger: new listing -> notify-new-listing ------------------------------
CREATE OR REPLACE FUNCTION public.notify_new_listing()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  settings private.push_settings%ROWTYPE;
BEGIN
  IF NEW.category_id IS NULL
     OR coalesce(NEW.moderation_status, 'active') <> 'active' THEN
    RETURN NEW;
  END IF;

  SELECT * INTO settings FROM private.push_settings WHERE id = 1;
  IF settings.functions_url IS NULL OR settings.admin_key IS NULL THEN
    RETURN NEW;
  END IF;

  -- pg_net is async: the insert never waits for, or fails because of, push.
  PERFORM net.http_post(
    url := settings.functions_url || '/notify-new-listing',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-admin-key', settings.admin_key
    ),
    body := jsonb_build_object('listing_id', NEW.id)
  );
  RETURN NEW;
END;
$$;
ALTER FUNCTION public.notify_new_listing() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.notify_new_listing() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS notify_new_listing_trigger ON public.listings;
CREATE TRIGGER notify_new_listing_trigger
AFTER INSERT ON public.listings
FOR EACH ROW EXECUTE FUNCTION public.notify_new_listing();

COMMIT;
