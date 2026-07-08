-- Run in Supabase SQL Editor after push_notifications.sql
-- Allows saving FCM tokens for guests (not logged in) so broadcasts reach everyone.

DROP POLICY IF EXISTS "device_tokens_select_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_delete_own" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_anon" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_anon" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_insert_auth" ON public.device_tokens;
DROP POLICY IF EXISTS "device_tokens_update_auth" ON public.device_tokens;

-- Guests: save token without user_id
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

-- Logged-in users: link token to account (or keep guest token)
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
