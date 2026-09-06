-- Historical compatibility: remote mvp_core initially exposed a smallint overload.
DROP FUNCTION IF EXISTS public.upsert_daily_checkin(public.mood_type,smallint,text);
REVOKE ALL ON FUNCTION public.upsert_daily_checkin(public.mood_type,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.upsert_daily_checkin(public.mood_type,integer,text) TO authenticated;
NOTIFY pgrst, 'reload schema';
