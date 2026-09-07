-- A user has at most one daily journal for a Vietnam calendar day.
-- The advisory lock makes the read-then-reuse operation safe for two devices
-- saving the same day concurrently without adding user_id redundantly to the
-- subtype table.
CREATE OR REPLACE FUNCTION public.save_journal_with_tags(
  p_type public.journal_type,
  p_data jsonb,
  p_names text[],
  p_journal_id uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  journal_id uuid;
  requested_date date;
BEGIN
  IF p_type = 'daily' AND p_journal_id IS NULL THEN
    requested_date := coalesce(
      (p_data->>'entry_date')::date,
      (now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date
    );
    PERFORM pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(u::text || ':' || requested_date::text, 0)
    );
    SELECT j.id INTO journal_id
    FROM public.journals j
    JOIN public.daily_journals d ON d.journal_id = j.id
    WHERE j.user_id = u
      AND j.journal_type = 'daily'
      AND j.deleted_at IS NULL
      AND d.entry_date = requested_date
    ORDER BY j.updated_at DESC
    LIMIT 1
    FOR UPDATE OF j;
  ELSIF p_type = 'daily' AND p_journal_id IS NOT NULL AND p_data ? 'entry_date' THEN
    requested_date := (p_data->>'entry_date')::date;
    IF EXISTS (
      SELECT 1
      FROM public.journals j
      JOIN public.daily_journals d ON d.journal_id = j.id
      WHERE j.user_id = u
        AND j.journal_type = 'daily'
        AND j.deleted_at IS NULL
        AND j.id <> p_journal_id
        AND d.entry_date = requested_date
    ) THEN
      RAISE EXCEPTION 'A daily journal already exists for this date'
        USING ERRCODE = '23505';
    END IF;
  END IF;

  journal_id := public.save_journal(p_type, p_data, coalesce(p_journal_id, journal_id));
  PERFORM public.set_journal_tags(journal_id, p_names);
  RETURN journal_id;
END;
$$;

REVOKE ALL ON FUNCTION public.save_journal_with_tags(public.journal_type, jsonb, text[], uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.save_journal_with_tags(public.journal_type, jsonb, text[], uuid) TO authenticated;

-- The wrapper is the only authenticated write path.  Keeping the underlying
-- RPC service-role/internal-only prevents bypassing the one-per-day rule.
REVOKE ALL ON FUNCTION public.save_journal(public.journal_type, jsonb, uuid) FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.save_journal_with_tags(public.journal_type, jsonb, text[], uuid)
IS 'Saves journal atomically; daily journals are reused per user and Vietnam calendar date.';
