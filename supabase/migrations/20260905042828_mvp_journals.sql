-- Journal writes are atomic RPCs. Early reading/editing of future letters is intentional.
ALTER TABLE public.future_letters RENAME COLUMN content_encrypted TO content;
COMMENT ON COLUMN public.future_letters.content IS 'User-readable content; no application-layer encryption is claimed. Protected by RLS.';
CREATE TABLE public.storage_cleanup_jobs(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL,
 journal_id uuid,
 bucket_id text NOT NULL CHECK(bucket_id='journal-media'),
 object_path text NOT NULL,
 not_before timestamptz NOT NULL,
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','processing','done')),
 attempts integer NOT NULL DEFAULT 0,
 lease_until timestamptz,
 last_error text,
 created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(bucket_id,object_path)
);
ALTER TABLE public.storage_cleanup_jobs ENABLE ROW LEVEL SECURITY;
CREATE INDEX storage_cleanup_due_idx ON public.storage_cleanup_jobs(not_before) WHERE status<>'done';

CREATE FUNCTION public.save_journal(p_type public.journal_type,p_data jsonb,p_journal_id uuid DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); jid uuid:=coalesce(p_journal_id,gen_random_uuid());
 j public.journals; old_delivery timestamptz; delivery timestamptz; written timestamptz; item jsonb; n integer;
BEGIN
 IF p_data IS NULL OR jsonb_typeof(p_data)<>'object' THEN RAISE EXCEPTION 'Journal data must be an object'; END IF;
 SELECT * INTO j FROM public.journals WHERE id=jid FOR UPDATE;
 IF FOUND THEN
  IF j.user_id<>u OR j.deleted_at IS NOT NULL THEN RAISE EXCEPTION 'Journal unavailable' USING ERRCODE='42501'; END IF;
  IF j.journal_type<>p_type THEN RAISE EXCEPTION 'Journal type is immutable'; END IF;
  UPDATE public.journals SET title=CASE WHEN p_data?'title' THEN p_data->>'title' ELSE title END,
   preview_text=CASE WHEN p_data?'preview_text' THEN p_data->>'preview_text' ELSE preview_text END,
   is_favorite=coalesce((p_data->>'is_favorite')::boolean,is_favorite),
   is_archived=coalesce((p_data->>'is_archived')::boolean,is_archived) WHERE id=jid;
 ELSE
  INSERT INTO public.journals(id,user_id,journal_type,title,preview_text,is_favorite,is_archived)
  VALUES(jid,u,p_type,p_data->>'title',p_data->>'preview_text',coalesce((p_data->>'is_favorite')::boolean,false),coalesce((p_data->>'is_archived')::boolean,false));
 END IF;
 CASE p_type
 WHEN 'daily' THEN
  INSERT INTO public.daily_journals(journal_id,checkin_id,entry_date,content,mood,mood_score,weather_note,location_note,is_draft)
  VALUES(jid,(p_data->>'checkin_id')::uuid,coalesce((p_data->>'entry_date')::date,(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date),
   coalesce(p_data->>'content',''),(p_data->>'mood')::public.mood_type,
   CASE p_data->>'mood' WHEN 'awful' THEN 1 WHEN 'sad' THEN 2 WHEN 'okay' THEN 3 WHEN 'good' THEN 4 WHEN 'great' THEN 5 END,
   p_data->>'weather_note',p_data->>'location_note',coalesce((p_data->>'is_draft')::boolean,false))
  ON CONFLICT(journal_id) DO UPDATE SET
   checkin_id=CASE WHEN p_data?'checkin_id' THEN EXCLUDED.checkin_id ELSE daily_journals.checkin_id END,
   entry_date=CASE WHEN p_data?'entry_date' THEN EXCLUDED.entry_date ELSE daily_journals.entry_date END,
   content=CASE WHEN p_data?'content' THEN EXCLUDED.content ELSE daily_journals.content END,
   mood=CASE WHEN p_data?'mood' THEN EXCLUDED.mood ELSE daily_journals.mood END,
   mood_score=CASE WHEN p_data?'mood' THEN EXCLUDED.mood_score ELSE daily_journals.mood_score END,
   weather_note=CASE WHEN p_data?'weather_note' THEN EXCLUDED.weather_note ELSE daily_journals.weather_note END,
   location_note=CASE WHEN p_data?'location_note' THEN EXCLUDED.location_note ELSE daily_journals.location_note END,
   is_draft=coalesce((p_data->>'is_draft')::boolean,daily_journals.is_draft);
 WHEN 'yearly' THEN
  INSERT INTO public.yearly_journals(journal_id,user_id,year,opening_message,reflection_content,gratitude_note,status,completed_at)
  VALUES(jid,u,coalesce((p_data->>'year')::integer,extract(year FROM now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::integer),
   p_data->>'opening_message',p_data->>'reflection_content',p_data->>'gratitude_note',
   coalesce((p_data->>'status')::public.yearly_journal_status,'draft'),CASE WHEN p_data->>'status'='completed' THEN now() END)
  ON CONFLICT(journal_id) DO UPDATE SET
   year=CASE WHEN p_data?'year' THEN EXCLUDED.year ELSE yearly_journals.year END,
   opening_message=CASE WHEN p_data?'opening_message' THEN EXCLUDED.opening_message ELSE yearly_journals.opening_message END,
   reflection_content=CASE WHEN p_data?'reflection_content' THEN EXCLUDED.reflection_content ELSE yearly_journals.reflection_content END,
   gratitude_note=CASE WHEN p_data?'gratitude_note' THEN EXCLUDED.gratitude_note ELSE yearly_journals.gratitude_note END,
   status=coalesce((p_data->>'status')::public.yearly_journal_status,yearly_journals.status),
   completed_at=CASE WHEN p_data?'status' THEN EXCLUDED.completed_at ELSE yearly_journals.completed_at END;
  IF p_data?'goals' THEN
   IF jsonb_typeof(p_data->'goals')<>'array' THEN RAISE EXCEPTION 'goals must be an array'; END IF;
   DELETE FROM public.yearly_goals WHERE yearly_journal_id=jid;
   n:=0; FOR item IN SELECT * FROM jsonb_array_elements(p_data->'goals') LOOP
    INSERT INTO public.yearly_goals(yearly_journal_id,title,description,progress_percent,is_completed,completed_at,order_index)
    VALUES(jid,item->>'title',item->>'description',coalesce((item->>'progress_percent')::smallint,0),coalesce((item->>'is_completed')::boolean,false),CASE WHEN (item->>'is_completed')::boolean THEN now() END,n);
    n:=n+1;
   END LOOP;
  END IF;
  IF p_data?'highlights' THEN
   IF jsonb_typeof(p_data->'highlights')<>'array' THEN RAISE EXCEPTION 'highlights must be an array'; END IF;
   DELETE FROM public.yearly_highlights WHERE yearly_journal_id=jid;
   n:=0; FOR item IN SELECT * FROM jsonb_array_elements(p_data->'highlights') LOOP
    INSERT INTO public.yearly_highlights(yearly_journal_id,title,description,event_date,order_index) VALUES(jid,item->>'title',item->>'description',(item->>'event_date')::date,n); n:=n+1;
   END LOOP;
  END IF;
  IF p_data?'lessons' THEN
   IF jsonb_typeof(p_data->'lessons')<>'array' THEN RAISE EXCEPTION 'lessons must be an array'; END IF;
   DELETE FROM public.yearly_lessons WHERE yearly_journal_id=jid;
   n:=0; FOR item IN SELECT * FROM jsonb_array_elements(p_data->'lessons') LOOP
    INSERT INTO public.yearly_lessons(yearly_journal_id,content,order_index) VALUES(jid,item->>'content',n); n:=n+1;
   END LOOP;
  END IF;
 WHEN 'future_letter' THEN
  SELECT deliver_at,written_at INTO old_delivery,written FROM public.future_letters WHERE journal_id=jid;
  written:=coalesce(written,now()); delivery:=coalesce((p_data->>'deliver_at')::timestamptz,old_delivery);
  IF delivery IS NULL THEN RAISE EXCEPTION 'deliver_at required'; END IF;
  INSERT INTO public.future_letters(journal_id,content,written_at,deliver_at,status,allow_edit_before_delivery,recipient_type,recipient_name)
  VALUES(jid,coalesce(p_data->>'content',''),written,delivery,'scheduled',true,coalesce((p_data->>'recipient_type')::public.future_letter_recipient_type,'self'),p_data->>'recipient_name')
  ON CONFLICT(journal_id) DO UPDATE SET
   content=CASE WHEN p_data?'content' THEN EXCLUDED.content ELSE future_letters.content END,
   deliver_at=EXCLUDED.deliver_at,allow_edit_before_delivery=true,
   recipient_type=CASE WHEN p_data?'recipient_type' THEN EXCLUDED.recipient_type ELSE future_letters.recipient_type END,
   recipient_name=CASE WHEN p_data?'recipient_name' THEN EXCLUDED.recipient_name ELSE future_letters.recipient_name END,
   status=CASE WHEN old_delivery IS DISTINCT FROM delivery THEN 'scheduled'::public.future_letter_status ELSE future_letters.status END,
   notification_scheduled=false,
   notification_sent_at=CASE WHEN old_delivery IS DISTINCT FROM delivery THEN NULL ELSE future_letters.notification_sent_at END;
  IF old_delivery IS DISTINCT FROM delivery THEN DELETE FROM public.notifications WHERE journal_id=jid; END IF;
 END CASE;
 RETURN jid;
END $$;

CREATE FUNCTION public.open_future_letter(p_journal_id uuid) RETURNS public.future_letters
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); r public.future_letters;
BEGIN
 UPDATE public.future_letters f SET opened_at=coalesce(opened_at,now()),status='opened'
 FROM public.journals j WHERE j.id=f.journal_id AND j.id=p_journal_id AND j.user_id=u AND j.deleted_at IS NULL RETURNING f.* INTO r;
 IF NOT FOUND THEN RAISE EXCEPTION 'Letter unavailable' USING ERRCODE='42501'; END IF;
 RETURN r;
END $$;

CREATE FUNCTION muse_private.queue_journal_files(u uuid,jid uuid,when_due timestamptz) RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path='' AS $$
 INSERT INTO public.storage_cleanup_jobs(user_id,journal_id,bucket_id,object_path,not_before)
 SELECT u,jid,o.bucket_id,o.name,when_due FROM storage.objects o
 WHERE o.bucket_id='journal-media' AND o.name LIKE u::text||'/'||jid::text||'/%'
 ON CONFLICT(bucket_id,object_path) DO UPDATE SET not_before=least(storage_cleanup_jobs.not_before,EXCLUDED.not_before)
$$;

CREATE FUNCTION public.soft_delete_journal(p_journal_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); deleted timestamptz;
BEGIN
 UPDATE public.journals SET deleted_at=coalesce(deleted_at,now()) WHERE id=p_journal_id AND user_id=u RETURNING deleted_at INTO deleted;
 IF NOT FOUND THEN RAISE EXCEPTION 'Journal unavailable' USING ERRCODE='42501'; END IF;
 DELETE FROM public.notifications WHERE journal_id=p_journal_id;
 PERFORM muse_private.queue_journal_files(u,p_journal_id,deleted+interval '30 days');
END $$;

CREATE FUNCTION public.request_account_deletion() RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user();
BEGIN
 INSERT INTO public.account_deletion_requests(user_id) VALUES(u) ON CONFLICT DO NOTHING;
 UPDATE public.journals SET deleted_at=coalesce(deleted_at,now()) WHERE user_id=u;
 DELETE FROM public.notifications WHERE user_id=u;
 INSERT INTO public.storage_cleanup_jobs(user_id,bucket_id,object_path,not_before)
 SELECT u,o.bucket_id,o.name,now() FROM storage.objects o WHERE o.bucket_id='journal-media' AND o.name LIKE u::text||'/%'
 ON CONFLICT(bucket_id,object_path) DO UPDATE SET not_before=now();
 UPDATE public.profiles SET account_status='deleted',deleted_at=now() WHERE id=u;
END $$;

CREATE FUNCTION muse_private.process_due_letters() RETURNS integer
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE f record; processed integer:=0;
BEGIN
 FOR f IN SELECT fl.journal_id,fl.deliver_at,j.user_id FROM public.future_letters fl
 JOIN public.journals j ON j.id=fl.journal_id JOIN public.profiles p ON p.id=j.user_id
 WHERE fl.deliver_at<=now() AND fl.notification_sent_at IS NULL AND fl.status IN ('scheduled','available','opened')
 AND j.deleted_at IS NULL AND p.deleted_at IS NULL AND p.account_status='active'
 FOR UPDATE OF fl SKIP LOCKED LOOP
  INSERT INTO public.notifications(user_id,journal_id,kind,scheduled_for) VALUES(f.user_id,f.journal_id,'future_letter_due',f.deliver_at) ON CONFLICT DO NOTHING;
  UPDATE public.future_letters SET notification_sent_at=now(),status=CASE WHEN status='scheduled' THEN 'available'::public.future_letter_status ELSE status END WHERE journal_id=f.journal_id;
  processed:=processed+1;
 END LOOP;
 RETURN processed;
END $$;

CREATE FUNCTION public.mark_notification_read(p_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user();
BEGIN
 UPDATE public.notifications SET read_at=coalesce(read_at,now()) WHERE id=p_id AND user_id=u;
 IF NOT FOUND THEN RAISE EXCEPTION 'Notification unavailable'; END IF;
END $$;

