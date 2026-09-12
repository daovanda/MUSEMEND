-- Keep the current pastel UI readable while dark mode is still incomplete.
ALTER TABLE public.user_settings
  ALTER COLUMN theme_mode
  SET DEFAULT 'light'::public.theme_mode_type;

-- `system` was the previous untouched default. Preserve explicit light/dark
-- choices while moving accounts that still use that default to the new one.
UPDATE public.user_settings
SET theme_mode = 'light'::public.theme_mode_type
WHERE theme_mode = 'system'::public.theme_mode_type;
