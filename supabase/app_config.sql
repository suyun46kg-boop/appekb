-- Run this in Supabase SQL Editor (Dashboard → SQL → New query)

CREATE TABLE IF NOT EXISTS public.app_config (
  id text PRIMARY KEY DEFAULT 'default',
  min_version text NOT NULL DEFAULT '1.0.0',
  latest_version text NOT NULL DEFAULT '1.0.0',
  message_ru text NOT NULL DEFAULT 'Доступна новая версия приложения. Обновите для продолжения работы.',
  message_ky text NOT NULL DEFAULT 'Колдонмонун жаңы версиясы бар. Улантуу үчүн жаңыртыңыз.',
  android_url text NOT NULL DEFAULT 'https://play.google.com/store/apps/details?id=mycompany.ekbkyrgyzdar',
  ios_url text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.app_config (id)
VALUES ('default')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "app_config_public_read" ON public.app_config;
CREATE POLICY "app_config_public_read"
  ON public.app_config
  FOR SELECT
  USING (true);
