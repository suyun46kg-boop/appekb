-- Push notifications setup for ekbkyrgyzdar
--
-- BEFORE using push:
-- 1) Create Firebase project: https://console.firebase.google.com
-- 2) Add Android app with package: mycompany.ekbkyrgyzdar
-- 3) Download google-services.json -> android/app/google-services.json
-- 4) Run: dart pub global activate flutterfire_cli && flutterfire configure
-- 5) Deploy edge function send-broadcast (see supabase/functions/send-broadcast)
-- 6) Set FIREBASE_SERVICE_ACCOUNT secret in Supabase for the edge function

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token text NOT NULL UNIQUE,
  platform text NOT NULL CHECK (platform IN ('android', 'ios')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx
  ON public.device_tokens(user_id);

CREATE TABLE IF NOT EXISTS public.broadcasts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  type text NOT NULL DEFAULT 'news' CHECK (type IN ('news', 'promo')),
  link_route text,
  image_url text,
  sent_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.broadcasts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "device_tokens_select_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_delete_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_anon" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_anon" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_auth" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_auth" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_select_auth" ON public.device_tokens;

CREATE POLICY "device_tokens_insert_anon"
  ON public.device_tokens
  FOR INSERT
  TO anon
  WITH CHECK (user_id IS NULL);

CREATE POLICY "device_tokens_update_anon"
  ON public.device_tokens
  FOR UPDATE
  TO anon
  USING (user_id IS NULL)
  WITH CHECK (user_id IS NULL);

CREATE POLICY "device_tokens_insert_auth"
  ON public.device_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "device_tokens_update_auth"
  ON public.device_tokens
  FOR UPDATE
  TO authenticated
  USING (user_id IS NULL OR auth.uid() = user_id)
  WITH CHECK (user_id IS NULL OR auth.uid() = user_id);

CREATE POLICY "device_tokens_select_auth"
  ON public.device_tokens
  FOR SELECT
  TO authenticated
  USING (user_id IS NULL OR auth.uid() = user_id);

DROP POLICY IF EXISTS "broadcasts_select_authenticated" ON public.broadcasts;
CREATE POLICY "broadcasts_select_authenticated"
  ON public.broadcasts
  FOR SELECT
  TO authenticated
  USING (true);
