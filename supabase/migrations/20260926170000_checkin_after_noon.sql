-- The check-in window follows the product day in Vietnam, independent of the
-- device clock. Keep the same RPC signature for existing clients.
CREATE FUNCTION muse_private.checkin_is_open(p_instant timestamptz)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path = ''
AS $$
  SELECT (p_instant AT TIME ZONE 'Asia/Ho_Chi_Minh')::time >= time '12:00';
$$;

REVOKE ALL ON FUNCTION muse_private.checkin_is_open(timestamptz)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION public.upsert_daily_checkin(
  p_mood public.mood_type,
  p_energy_level integer DEFAULT NULL,
  p_note text DEFAULT NULL
)
RETURNS public.daily_checkins
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  r public.daily_checkins;
BEGIN
  IF NOT muse_private.checkin_is_open(now()) THEN
    RAISE EXCEPTION 'Check-in opens at 12:00 Asia/Ho_Chi_Minh'
      USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.daily_checkins(
    user_id, mood, mood_score, energy_level, note_short
  )
  VALUES (
    u,
    p_mood,
    CASE p_mood
      WHEN 'awful' THEN 1
      WHEN 'sad' THEN 2
      WHEN 'okay' THEN 3
      WHEN 'good' THEN 4
      WHEN 'great' THEN 5
    END,
    p_energy_level::smallint,
    p_note
  )
  ON CONFLICT (user_id, checkin_date) DO UPDATE SET
    mood = EXCLUDED.mood,
    mood_score = EXCLUDED.mood_score,
    energy_level = EXCLUDED.energy_level,
    note_short = EXCLUDED.note_short,
    deleted_at = NULL
  RETURNING * INTO r;

  RETURN r;
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_daily_checkin(public.mood_type, integer, text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.upsert_daily_checkin(public.mood_type, integer, text)
  TO authenticated;
