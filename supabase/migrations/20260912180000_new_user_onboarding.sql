-- Persist onboarding completion across devices without exposing profile state writes.
ALTER TABLE public.profiles
  ADD COLUMN onboarding_completed_at timestamptz,
  ADD COLUMN preferred_address text;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_preferred_address_check
  CHECK (
    preferred_address IS NULL OR preferred_address IN (
      'cau_minh',
      'ban_minh',
      'anh_em',
      'chi_em',
      'ten_rieng'
    )
  );

-- Existing accounts must keep their current login experience. New profiles created
-- after this migration retain the NULL default and are routed through onboarding.
UPDATE public.profiles
SET onboarding_completed_at = now()
WHERE onboarding_completed_at IS NULL;

CREATE FUNCTION public.complete_onboarding(
  p_display_name text DEFAULT NULL,
  p_preferred_address text DEFAULT NULL
)
RETURNS public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  normalized_name text := nullif(btrim(p_display_name), '');
  result public.profiles;
BEGIN
  IF normalized_name IS NOT NULL AND char_length(normalized_name) NOT BETWEEN 2 AND 80 THEN
    RAISE EXCEPTION 'Display name must contain 2-80 characters'
      USING ERRCODE = '22023';
  END IF;

  IF p_preferred_address IS NOT NULL AND p_preferred_address NOT IN (
    'cau_minh',
    'ban_minh',
    'anh_em',
    'chi_em',
    'ten_rieng'
  ) THEN
    RAISE EXCEPTION 'Unsupported preferred address'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.profiles
  SET display_name = coalesce(normalized_name, display_name),
      preferred_address = p_preferred_address,
      onboarding_completed_at = coalesce(onboarding_completed_at, now())
  WHERE id = u
  RETURNING * INTO result;

  RETURN result;
END;
$$;

REVOKE ALL ON FUNCTION public.complete_onboarding(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_onboarding(text, text) TO authenticated;
