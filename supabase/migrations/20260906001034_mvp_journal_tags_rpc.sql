CREATE FUNCTION public.set_journal_tags(p_journal_id uuid, p_names text[])
RETURNS SETOF public.journal_tags
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  u uuid := muse_private.require_user();
  cleaned text[];
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.journals
    WHERE id = p_journal_id AND user_id = u AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Journal unavailable' USING ERRCODE = '42501';
  END IF;

  SELECT coalesce(array_agg(name ORDER BY lower(name)), ARRAY[]::text[])
  INTO cleaned
  FROM (
    SELECT min(btrim(value)) AS name
    FROM unnest(coalesce(p_names, ARRAY[]::text[])) AS value
    WHERE btrim(value) <> ''
    GROUP BY lower(btrim(value))
  ) names;

  IF cardinality(cleaned) > 8 THEN
    RAISE EXCEPTION 'A journal can have at most 8 tags' USING ERRCODE = '22023';
  END IF;
  IF EXISTS (SELECT 1 FROM unnest(cleaned) AS name WHERE char_length(name) > 40) THEN
    RAISE EXCEPTION 'Tag names are limited to 40 characters' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.journal_tags(user_id, name)
  SELECT u, name FROM unnest(cleaned) AS name
  ON CONFLICT (user_id, normalized_name)
  DO UPDATE SET name = excluded.name;

  DELETE FROM public.journal_tag_assignments WHERE journal_id = p_journal_id;
  INSERT INTO public.journal_tag_assignments(journal_id, tag_id)
  SELECT p_journal_id, t.id
  FROM public.journal_tags t
  WHERE t.user_id = u
    AND t.deleted_at IS NULL
    AND t.normalized_name = ANY(SELECT lower(name) FROM unnest(cleaned) AS name);

  RETURN QUERY
  SELECT t.*
  FROM public.journal_tags t
  JOIN public.journal_tag_assignments a ON a.tag_id = t.id
  WHERE a.journal_id = p_journal_id
  ORDER BY lower(t.name);
END;
$$;

CREATE FUNCTION public.save_journal_with_tags(
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
  journal_id uuid;
BEGIN
  journal_id := public.save_journal(p_type, p_data, p_journal_id);
  PERFORM public.set_journal_tags(journal_id, p_names);
  RETURN journal_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_journal_tags(uuid, text[]) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.save_journal_with_tags(public.journal_type, jsonb, text[], uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_journal_tags(uuid, text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_journal_with_tags(public.journal_type, jsonb, text[], uuid) TO authenticated;
