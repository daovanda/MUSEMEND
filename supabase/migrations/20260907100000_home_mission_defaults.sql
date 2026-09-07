-- Ensure the Home sky screen has two gentle starter missions for every user.
-- The catalog row and user snapshot are both server-owned; clients only invoke
-- this idempotent command and never choose a reward or occurrence key.
INSERT INTO public.mission_templates(
  code,
  title,
  description,
  mission_type,
  target_mood,
  default_energy_reward,
  estimated_minutes
)
VALUES (
  'demo-walk',
  'Đi bộ 5 phút',
  'Vận động nhẹ nhàng nếu cơ thể sẵn sàng.',
  'daily',
  'all',
  5,
  5
)
ON CONFLICT (code) DO NOTHING;

CREATE FUNCTION public.ensure_home_missions()
RETURNS SETOF public.user_missions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  starter_count integer;
  template_row public.mission_templates;
BEGIN
  -- Locks and validates the current profile before creating any snapshot.
  PERFORM muse_private.require_user();

  SELECT count(*)::integer
  INTO starter_count
  FROM public.mission_templates
  WHERE code IN ('demo-water', 'demo-walk')
    AND is_active;

  IF starter_count <> 2 THEN
    RAISE EXCEPTION 'Home mission catalog unavailable';
  END IF;

  FOR template_row IN
    SELECT *
    FROM public.mission_templates
    WHERE code IN ('demo-water', 'demo-walk')
      AND is_active
    ORDER BY id
  LOOP
    -- create_mission owns validation, snapshotting, daily occurrence keys and
    -- ON CONFLICT idempotency. The function remains a short DB transaction.
    RETURN NEXT public.create_mission(template_row.id, NULL, NULL, NULL, NULL);
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.ensure_home_missions() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_home_missions() TO authenticated;

NOTIFY pgrst, 'reload schema';
