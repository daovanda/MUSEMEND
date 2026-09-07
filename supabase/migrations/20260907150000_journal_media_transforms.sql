-- Persist the free-form image layout used by the journal editor.
-- Coordinates are normalized to the editor canvas center; scale keeps the
-- original aspect ratio and rotation is stored in radians.
ALTER TABLE public.journal_media
  ADD COLUMN IF NOT EXISTS position_x numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS position_y numeric NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS display_scale numeric NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS rotation_radians numeric NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'journal_media_transform_bounds'
      AND conrelid = 'public.journal_media'::regclass
  ) THEN
    ALTER TABLE public.journal_media
      ADD CONSTRAINT journal_media_transform_bounds CHECK (
        position_x BETWEEN -2 AND 2
        AND position_y BETWEEN -2 AND 2
        AND display_scale BETWEEN 0.1 AND 5
        AND rotation_radians BETWEEN -100000 AND 100000
      );
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_journal_media_transform(
  p_media_id uuid,
  p_position_x numeric,
  p_position_y numeric,
  p_display_scale numeric,
  p_rotation_radians numeric
)
RETURNS public.journal_media
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  media public.journal_media;
BEGIN
  IF p_position_x IS NULL OR p_position_y IS NULL
     OR p_display_scale IS NULL OR p_rotation_radians IS NULL
     OR p_position_x NOT BETWEEN -2 AND 2
     OR p_position_y NOT BETWEEN -2 AND 2
     OR p_display_scale NOT BETWEEN 0.1 AND 5
     OR p_rotation_radians NOT BETWEEN -100000 AND 100000 THEN
    RAISE EXCEPTION 'Invalid media transform' USING ERRCODE = '22023';
  END IF;

  UPDATE public.journal_media m
  SET position_x = p_position_x,
      position_y = p_position_y,
      display_scale = p_display_scale,
      rotation_radians = p_rotation_radians,
      updated_at = now()
  FROM public.journals j
  WHERE m.id = p_media_id
    AND m.journal_id = j.id
    AND m.deleted_at IS NULL
    AND j.user_id = u
    AND j.deleted_at IS NULL
  RETURNING m.* INTO media;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Media unavailable' USING ERRCODE = '42501';
  END IF;
  RETURN media;
END;
$$;

REVOKE ALL ON FUNCTION public.update_journal_media_transform(uuid, numeric, numeric, numeric, numeric)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_journal_media_transform(uuid, numeric, numeric, numeric, numeric)
  TO authenticated;

COMMENT ON FUNCTION public.update_journal_media_transform(uuid, numeric, numeric, numeric, numeric)
IS 'Updates owner-scoped journal image position, scale and rotation without changing the stored object.';
