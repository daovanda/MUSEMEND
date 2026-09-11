-- Add explicit mission scheduling and server-owned daily recurrence.
-- All calendar boundaries use the product timezone (Asia/Ho_Chi_Minh).

ALTER TABLE public.user_missions
  ADD COLUMN recurrence_series_id uuid;

ALTER TABLE public.user_missions
  ADD CONSTRAINT user_missions_schedule_order
  CHECK (due_at IS NULL OR due_at > start_at) NOT VALID;

ALTER TABLE public.user_missions
  VALIDATE CONSTRAINT user_missions_schedule_order;

CREATE INDEX user_missions_daily_series_idx
  ON public.user_missions(user_id, recurrence_series_id, start_at DESC)
  WHERE recurrence_series_id IS NOT NULL AND deleted_at IS NULL;

CREATE FUNCTION public.create_scheduled_mission(
  p_mission_type public.mission_type,
  p_template_id bigint,
  p_title text,
  p_description text,
  p_start_at timestamptz,
  p_due_at timestamptz,
  p_checkin_id uuid,
  p_request_id uuid
)
RETURNS public.user_missions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  t public.mission_templates;
  r public.user_missions;
  resolved_type public.mission_type := p_mission_type;
  resolved_start timestamptz;
  resolved_due timestamptz;
  resolved_title text;
  resolved_description text;
  resolved_reward integer;
  resolved_source public.mission_source_type;
  resolved_checkin uuid;
  request_id uuid := coalesce(p_request_id, gen_random_uuid());
  series_id uuid;
  today date := (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
  period_start date;
  occurrence text;
BEGIN
  IF resolved_type IS NULL OR resolved_type NOT IN ('daily', 'weekly', 'monthly', 'yearly', 'custom') THEN
    RAISE EXCEPTION 'Unsupported mission type';
  END IF;

  IF p_template_id IS NULL THEN
    IF p_title IS NULL OR length(btrim(p_title)) NOT BETWEEN 1 AND 200 THEN
      RAISE EXCEPTION 'Title must contain 1-200 characters';
    END IF;
    IF p_checkin_id IS NOT NULL THEN
      RAISE EXCEPTION 'User-created mission cannot impersonate a mood mission';
    END IF;
    resolved_title := btrim(p_title);
    resolved_description := nullif(btrim(p_description), '');
    resolved_reward := 5;
    resolved_source := 'user_created';
    resolved_checkin := NULL;
  ELSE
    SELECT * INTO t
    FROM public.mission_templates
    WHERE id = p_template_id AND is_active;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Template unavailable';
    END IF;
    IF t.mission_type <> resolved_type THEN
      RAISE EXCEPTION 'Template mission type mismatch';
    END IF;
    IF p_checkin_id IS NOT NULL AND NOT EXISTS (
      SELECT 1
      FROM public.daily_checkins
      WHERE id = p_checkin_id
        AND user_id = u
        AND deleted_at IS NULL
    ) THEN
      RAISE EXCEPTION 'Check-in unavailable';
    END IF;
    IF t.target_mood <> 'all' AND NOT EXISTS (
      SELECT 1
      FROM public.daily_checkins
      WHERE user_id = u
        AND checkin_date = today
        AND deleted_at IS NULL
        AND mood::text = t.target_mood::text
    ) THEN
      RAISE EXCEPTION 'Template does not match today mood';
    END IF;

    resolved_title := t.title;
    resolved_description := t.description;
    resolved_reward := t.default_energy_reward;
    resolved_source := CASE
      WHEN p_checkin_id IS NULL THEN 'system'::public.mission_source_type
      ELSE 'mood_checkin'::public.mission_source_type
    END;
    resolved_checkin := p_checkin_id;
  END IF;

  CASE resolved_type
    WHEN 'daily' THEN
      IF p_start_at IS NULL OR p_due_at IS NULL OR p_due_at <= p_start_at THEN
        RAISE EXCEPTION 'Daily mission requires a valid start and end time';
      END IF;
      IF (p_start_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date <> today
         OR (p_due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date <> today THEN
        RAISE EXCEPTION 'Daily mission must start and end today';
      END IF;
      resolved_start := p_start_at;
      resolved_due := p_due_at;
      series_id := request_id;
      occurrence := 'series:' || series_id::text || ':' || today::text;

      IF p_template_id IS NOT NULL THEN
        SELECT * INTO r
        FROM public.user_missions
        WHERE user_id = u
          AND template_id = p_template_id
          AND recurrence_series_id IS NOT NULL
          AND deleted_at IS NULL
        ORDER BY created_at DESC
        LIMIT 1;
        IF FOUND THEN
          RETURN r;
        END IF;
      END IF;

    WHEN 'weekly' THEN
      period_start := date_trunc('week', today::timestamp)::date;
      resolved_start := now();
      resolved_due := ((period_start + 7)::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh');
      occurrence := CASE WHEN p_template_id IS NULL
        THEN 'request:' || request_id::text
        ELSE 'template:' || p_template_id::text || ':weekly:' || period_start::text
      END;

    WHEN 'monthly' THEN
      period_start := date_trunc('month', today::timestamp)::date;
      resolved_start := now();
      resolved_due := ((period_start::timestamp + interval '1 month') AT TIME ZONE 'Asia/Ho_Chi_Minh');
      occurrence := CASE WHEN p_template_id IS NULL
        THEN 'request:' || request_id::text
        ELSE 'template:' || p_template_id::text || ':monthly:' || period_start::text
      END;

    WHEN 'yearly' THEN
      period_start := date_trunc('year', today::timestamp)::date;
      resolved_start := now();
      resolved_due := ((period_start::timestamp + interval '1 year') AT TIME ZONE 'Asia/Ho_Chi_Minh');
      occurrence := CASE WHEN p_template_id IS NULL
        THEN 'request:' || request_id::text
        ELSE 'template:' || p_template_id::text || ':yearly:' || period_start::text
      END;

    WHEN 'custom' THEN
      IF p_start_at IS NULL OR p_due_at IS NULL OR p_due_at <= p_start_at OR p_due_at <= now() THEN
        RAISE EXCEPTION 'Custom mission requires a valid future end time';
      END IF;
      resolved_start := p_start_at;
      resolved_due := p_due_at;
      occurrence := CASE WHEN p_template_id IS NULL
        THEN 'request:' || request_id::text
        ELSE 'template:' || p_template_id::text || ':custom:' || request_id::text
      END;
  END CASE;

  INSERT INTO public.user_missions(
    user_id,
    template_id,
    source_type,
    source_checkin_id,
    mission_type,
    title_snapshot,
    description_snapshot,
    energy_reward,
    start_at,
    due_at,
    occurrence_key,
    recurrence_series_id
  )
  VALUES (
    u,
    p_template_id,
    resolved_source,
    resolved_checkin,
    resolved_type,
    resolved_title,
    resolved_description,
    resolved_reward,
    resolved_start,
    resolved_due,
    occurrence,
    series_id
  )
  ON CONFLICT (user_id, occurrence_key)
    WHERE occurrence_key IS NOT NULL
    DO NOTHING;

  SELECT * INTO r
  FROM public.user_missions
  WHERE user_id = u AND occurrence_key = occurrence;

  RETURN r;
END;
$$;

-- Adopt existing daily template selections as recurring series. One series is
-- shared by the historical occurrences of the same template for the same user.
WITH existing_series AS (
  SELECT user_id, template_id, gen_random_uuid() AS series_id
  FROM public.user_missions
  WHERE mission_type = 'daily'
    AND template_id IS NOT NULL
    AND recurrence_series_id IS NULL
    AND deleted_at IS NULL
  GROUP BY user_id, template_id
)
UPDATE public.user_missions AS mission
SET recurrence_series_id = existing_series.series_id
FROM existing_series
WHERE mission.user_id = existing_series.user_id
  AND mission.template_id = existing_series.template_id
  AND mission.mission_type = 'daily'
  AND mission.recurrence_series_id IS NULL
  AND mission.deleted_at IS NULL;

CREATE FUNCTION public.refresh_scheduled_missions()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  today date := (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
  previous public.user_missions;
  new_start timestamptz;
  new_due timestamptz;
  due_day_offset integer;
  inserted_count integer := 0;
BEGIN
  UPDATE public.user_missions
  SET status = 'expired'
  WHERE user_id = u
    AND status IN ('pending', 'in_progress')
    AND due_at IS NOT NULL
    AND due_at <= now()
    AND deleted_at IS NULL;

  FOR previous IN
    SELECT DISTINCT ON (recurrence_series_id) *
    FROM public.user_missions
    WHERE user_id = u
      AND mission_type = 'daily'
      AND recurrence_series_id IS NOT NULL
      AND deleted_at IS NULL
      AND (start_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date < today
    ORDER BY recurrence_series_id, start_at DESC, created_at DESC
  LOOP
    due_day_offset :=
      (previous.due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
      - (previous.start_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
    new_start := (
      today::timestamp
      + (previous.start_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::time
    ) AT TIME ZONE 'Asia/Ho_Chi_Minh';
    new_due := (
      (today + due_day_offset)::timestamp
      + (previous.due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::time
    ) AT TIME ZONE 'Asia/Ho_Chi_Minh';

    INSERT INTO public.user_missions(
      user_id,
      template_id,
      source_type,
      source_checkin_id,
      mission_type,
      title_snapshot,
      description_snapshot,
      energy_reward,
      start_at,
      due_at,
      occurrence_key,
      recurrence_series_id
    ) VALUES (
      u,
      previous.template_id,
      previous.source_type,
      NULL,
      'daily',
      previous.title_snapshot,
      previous.description_snapshot,
      previous.energy_reward,
      new_start,
      new_due,
      'series:' || previous.recurrence_series_id::text || ':' || today::text,
      previous.recurrence_series_id
    )
    ON CONFLICT (user_id, occurrence_key)
      WHERE occurrence_key IS NOT NULL
      DO NOTHING;

    IF FOUND THEN
      inserted_count := inserted_count + 1;
    END IF;
  END LOOP;

  RETURN inserted_count;
END;
$$;

CREATE OR REPLACE FUNCTION public.ensure_home_missions()
RETURNS SETOF public.user_missions
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  starter_count integer;
  template_row public.mission_templates;
  today date := (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
  start_time time;
  end_time time;
BEGIN
  PERFORM muse_private.require_user();

  SELECT count(*)::integer
  INTO starter_count
  FROM public.mission_templates
  WHERE code IN ('demo-water', 'demo-walk') AND is_active;

  IF starter_count <> 2 THEN
    RAISE EXCEPTION 'Home mission catalog unavailable';
  END IF;

  FOR template_row IN
    SELECT *
    FROM public.mission_templates
    WHERE code IN ('demo-water', 'demo-walk') AND is_active
    ORDER BY id
  LOOP
    start_time := time '00:00';
    end_time := time '23:59:59';

    RETURN NEXT public.create_scheduled_mission(
      'daily',
      template_row.id,
      NULL,
      NULL,
      (today::timestamp + start_time) AT TIME ZONE 'Asia/Ho_Chi_Minh',
      (today::timestamp + end_time) AT TIME ZONE 'Asia/Ho_Chi_Minh',
      NULL,
      gen_random_uuid()
    );
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.create_scheduled_mission(
  public.mission_type,
  bigint,
  text,
  text,
  timestamptz,
  timestamptz,
  uuid,
  uuid
) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.create_scheduled_mission(
  public.mission_type,
  bigint,
  text,
  text,
  timestamptz,
  timestamptz,
  uuid,
  uuid
) TO authenticated;

REVOKE ALL ON FUNCTION public.refresh_scheduled_missions()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_scheduled_missions()
  TO authenticated;

-- Ensure the suggestion catalog represents every scheduling type exposed by
-- the client. Existing daily/weekly/monthly rows remain the primary catalog.
INSERT INTO public.mission_templates(
  code,
  title,
  description,
  mission_type,
  target_mood,
  default_energy_reward,
  difficulty,
  estimated_minutes
)
VALUES
  (
    'schedule-yearly-kindness',
    'Chọn một điều muốn nuôi dưỡng trong năm',
    'Viết lại một thay đổi nhỏ bạn muốn kiên trì với chính mình.',
    'yearly',
    'all',
    20,
    'medium',
    15
  ),
  (
    'schedule-custom-rest',
    'Hẹn một khoảng nghỉ cho riêng mình',
    'Chọn ngày giờ phù hợp để dành một khoảng thở không vội vàng.',
    'custom',
    'all',
    5,
    'easy',
    10
  )
ON CONFLICT (code) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  mission_type = EXCLUDED.mission_type,
  target_mood = EXCLUDED.target_mood,
  default_energy_reward = EXCLUDED.default_energy_reward,
  difficulty = EXCLUDED.difficulty,
  estimated_minutes = EXCLUDED.estimated_minutes,
  is_system = true,
  is_active = true;

NOTIFY pgrst, 'reload schema';
