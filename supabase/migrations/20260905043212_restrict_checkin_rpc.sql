REVOKE ALL ON FUNCTION public.upsert_daily_checkin(public.mood_type,integer,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.upsert_daily_checkin(public.mood_type,integer,text) TO authenticated;

