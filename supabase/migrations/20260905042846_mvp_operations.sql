ALTER TABLE public.storage_cleanup_jobs ADD COLUMN lease_token uuid;

CREATE FUNCTION public.claim_storage_cleanup(p_limit integer DEFAULT 50)
RETURNS SETOF public.storage_cleanup_jobs LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 UPDATE public.storage_cleanup_jobs q SET status='processing',attempts=attempts+1,lease_until=now()+interval '10 minutes',lease_token=gen_random_uuid()
 WHERE q.id IN(SELECT id FROM public.storage_cleanup_jobs WHERE not_before<=now() AND (status='pending' OR (status='processing' AND lease_until<now())) ORDER BY not_before LIMIT greatest(1,least(p_limit,100)) FOR UPDATE SKIP LOCKED)
 RETURNING q.*
$$;
CREATE FUNCTION public.finish_storage_cleanup(p_id uuid,p_lease uuid,p_error text DEFAULT NULL) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 UPDATE public.storage_cleanup_jobs SET status=CASE WHEN p_error IS NULL THEN 'done' ELSE 'pending' END,
 last_error=left(p_error,500),lease_until=NULL,lease_token=NULL,
 not_before=CASE WHEN p_error IS NULL THEN not_before ELSE now()+interval '15 minutes' END
 WHERE id=p_id AND lease_token=p_lease AND status='processing';
 IF NOT FOUND THEN RAISE EXCEPTION 'Cleanup lease expired'; END IF;
END $$;
CREATE FUNCTION public.list_ready_account_deletions()
RETURNS TABLE(user_id uuid) LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 SELECT r.user_id FROM public.account_deletion_requests r
 WHERE NOT EXISTS(SELECT 1 FROM public.storage_cleanup_jobs q WHERE q.user_id=r.user_id AND q.status<>'done')
 AND NOT EXISTS(SELECT 1 FROM storage.objects o WHERE o.bucket_id='journal-media' AND o.name LIKE r.user_id::text||'/%')
 ORDER BY r.requested_at LIMIT 100
$$;
CREATE FUNCTION muse_private.housekeeping() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 PERFORM muse_private.process_due_letters();
 -- Re-scan account prefixes for uploads that were in flight at the moment deletion was requested.
 INSERT INTO public.storage_cleanup_jobs(user_id,bucket_id,object_path,not_before)
 SELECT r.user_id,o.bucket_id,o.name,now() FROM public.account_deletion_requests r JOIN storage.objects o
 ON o.bucket_id='journal-media' AND o.name LIKE r.user_id::text||'/%'
 ON CONFLICT(bucket_id,object_path) DO UPDATE SET status='pending',not_before=now()
 WHERE storage_cleanup_jobs.status='done';
 -- Remove relational journal data only after its retention window and actual Storage deletion.
 DELETE FROM public.journals j WHERE j.deleted_at<=now()-interval '30 days'
 AND NOT EXISTS(SELECT 1 FROM public.storage_cleanup_jobs q WHERE q.journal_id=j.id AND q.status<>'done')
 AND NOT EXISTS(SELECT 1 FROM storage.objects o WHERE o.bucket_id='journal-media' AND o.name LIKE j.user_id::text||'/'||j.id::text||'/%');
 DELETE FROM public.storage_cleanup_jobs q WHERE q.status='done' AND NOT EXISTS(SELECT 1 FROM auth.users a WHERE a.id=q.user_id);
END $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA muse_private FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION muse_private.active_user(),muse_private.can_access_journal_object(text) TO authenticated;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_daily_checkin(public.mood_type,integer,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_app_open() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_mission(bigint,text,text,uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_custom_mission(uuid,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.skip_mission(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.start_journey() TO authenticated;
GRANT EXECUTE ON FUNCTION public.advance_journey() TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_mission(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_item_equipped(bigint,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_journal(public.journal_type,jsonb,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.open_future_letter(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_journal(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.request_account_deletion() TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_notification_read(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.attach_journal_media(uuid,text,public.media_type,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_journal_media(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_storage_cleanup(integer),public.finish_storage_cleanup(uuid,uuid,text),public.list_ready_account_deletions() TO service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE,SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;
NOTIFY pgrst, 'reload schema';
