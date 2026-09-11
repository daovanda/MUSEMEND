BEGIN;
DO $$
BEGIN
 IF (SELECT count(*) FROM public.provinces WHERE code LIKE 'curated-%') <> 10 THEN RAISE EXCEPTION 'curated destinations missing'; END IF;
 IF (SELECT count(*) FROM public.province_checkpoints c JOIN public.provinces p ON p.id=c.province_id WHERE p.code LIKE 'curated-%' AND c.asset_path IS NOT NULL) <> 10 THEN RAISE EXCEPTION 'curated checkpoint artwork missing'; END IF;
 IF (SELECT count(*) FROM public.landmarks WHERE code LIKE 'curated-%') <> 10 THEN RAISE EXCEPTION 'curated landmarks missing'; END IF;
 IF (SELECT count(*) FROM public.foods WHERE code LIKE 'curated-%') <> 10 THEN RAISE EXCEPTION 'curated foods missing'; END IF;
 IF (SELECT count(*) FROM public.province_items WHERE code LIKE 'curated-%') <> 10 THEN RAISE EXCEPTION 'curated items missing'; END IF;
 IF (SELECT count(*) FROM public.mission_templates WHERE code LIKE 'curated-%') <> 10 THEN RAISE EXCEPTION 'curated missions missing'; END IF;
 IF (SELECT count(*) FROM public.checkpoint_rewards r JOIN public.province_checkpoints c ON c.id=r.checkpoint_id JOIN public.provinces p ON p.id=c.province_id WHERE p.code LIKE 'curated-%') <> 30 THEN RAISE EXCEPTION 'curated rewards missing'; END IF;
 IF EXISTS(SELECT 1 FROM public.provinces WHERE code LIKE 'curated-%' AND country_code IS NULL) THEN RAISE EXCEPTION 'curated destination country missing'; END IF;
 IF (SELECT count(DISTINCT mission_type) FROM public.mission_templates WHERE is_active AND mission_type IN ('daily','weekly','monthly','yearly','custom'))<>5 THEN RAISE EXCEPTION 'mission suggestion types missing'; END IF;
END $$;
INSERT INTO auth.users(id,email,raw_user_meta_data,raw_app_meta_data) VALUES
 ('10000000-0000-4000-8000-000000000001','a@example.invalid','{"display_name":"A"}','{"provider":"email"}'),
 ('20000000-0000-4000-8000-000000000002','b@example.invalid','{"display_name":"B"}','{"provider":"email"}');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE c public.daily_checkins; c2 public.daily_checkins; v jsonb; m public.user_missions; scheduled public.user_missions; r jsonb; p public.travel_progress; j uuid; j2 uuid; media_id uuid; media_path text; starter_count integer; blocked boolean:=false; today date:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
BEGIN
 SELECT * INTO c FROM public.upsert_daily_checkin('sad',2,'first');
 SELECT * INTO c2 FROM public.upsert_daily_checkin('good',4,'edited');
 IF c.id<>c2.id OR c2.mood<>'good' OR (SELECT count(*) FROM public.daily_checkins)<>1 THEN RAISE EXCEPTION 'check-in failed'; END IF;
 SELECT public.record_app_open() INTO v; PERFORM public.record_app_open();
 IF (v->>'streak')::int<>1 OR (SELECT count(*) FROM public.daily_visits)<>1 THEN RAISE EXCEPTION 'streak failed'; END IF;
 SELECT count(*) INTO starter_count FROM public.ensure_home_missions();
 IF starter_count<>2 OR (SELECT count(*) FROM public.user_missions WHERE source_type='system')<>2 THEN RAISE EXCEPTION 'home starter missions failed'; END IF;
 SELECT count(*) INTO starter_count FROM public.ensure_home_missions();
 IF starter_count<>2 OR (SELECT count(*) FROM public.user_missions WHERE source_type='system')<>2 THEN RAISE EXCEPTION 'home starter missions are not idempotent'; END IF;
 SELECT * INTO scheduled FROM public.create_scheduled_mission('daily',NULL,'Daily scheduled','repeat tomorrow',((today::timestamp+time '00:00') AT TIME ZONE 'Asia/Ho_Chi_Minh'),((today::timestamp+time '23:59:59') AT TIME ZONE 'Asia/Ho_Chi_Minh'),NULL,'60000000-0000-4000-8000-000000000006');
 IF scheduled.energy_reward<>5 OR scheduled.recurrence_series_id IS NULL OR scheduled.start_at>=scheduled.due_at THEN RAISE EXCEPTION 'daily scheduling failed'; END IF;
 PERFORM set_config('app.test.daily_mission',scheduled.id::text,true);
 PERFORM set_config('app.test.daily_series',scheduled.recurrence_series_id::text,true);
 SELECT * INTO scheduled FROM public.create_scheduled_mission('weekly',NULL,'Weekly scheduled',NULL,NULL,NULL,NULL,'70000000-0000-4000-8000-000000000007');
 IF (scheduled.due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date<>date_trunc('week',today::timestamp)::date+7 OR (scheduled.due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::time<>time '00:00' THEN RAISE EXCEPTION 'weekly boundary failed'; END IF;
 SELECT * INTO scheduled FROM public.create_scheduled_mission('monthly',NULL,'Monthly scheduled',NULL,NULL,NULL,NULL,'80000000-0000-4000-8000-000000000008');
 IF (scheduled.due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date<>(date_trunc('month',today::timestamp)+interval '1 month')::date THEN RAISE EXCEPTION 'monthly boundary failed'; END IF;
 SELECT * INTO scheduled FROM public.create_scheduled_mission('yearly',NULL,'Yearly scheduled',NULL,NULL,NULL,NULL,'90000000-0000-4000-8000-000000000009');
 IF (scheduled.due_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date<>(date_trunc('year',today::timestamp)+interval '1 year')::date THEN RAISE EXCEPTION 'yearly boundary failed'; END IF;
 SELECT * INTO scheduled FROM public.create_scheduled_mission('custom',NULL,'Custom scheduled',NULL,now()+interval '1 hour',now()+interval '2 hours',NULL,'a0000000-0000-4000-8000-00000000000a');
 IF scheduled.mission_type<>'custom' OR scheduled.due_at<=scheduled.start_at THEN RAISE EXCEPTION 'custom schedule failed'; END IF;
 BEGIN
  PERFORM public.create_scheduled_mission('daily',NULL,'Invalid daily',NULL,((today::timestamp+time '10:00') AT TIME ZONE 'Asia/Ho_Chi_Minh'),((today::timestamp+time '09:00') AT TIME ZONE 'Asia/Ho_Chi_Minh'),NULL,'b0000000-0000-4000-8000-00000000000b');
 EXCEPTION WHEN raise_exception THEN blocked:=true;
 END;
 IF NOT blocked THEN RAISE EXCEPTION 'invalid daily schedule accepted'; END IF;
 SELECT * INTO m FROM public.create_mission(NULL,'Custom task','private',NULL,'30000000-0000-4000-8000-000000000003');
 IF m.energy_reward<>5 THEN RAISE EXCEPTION 'custom reward failed'; END IF;
 PERFORM public.start_journey(); PERFORM public.complete_mission(m.id); SELECT public.complete_mission(m.id) INTO r;
 IF NOT (r->>'already_completed')::boolean OR (SELECT current_energy FROM public.travel_progress WHERE user_id=auth.uid())<>5 THEN RAISE EXCEPTION 'idempotency failed'; END IF;
 SELECT * INTO m FROM public.create_mission(NULL,'Second task',NULL,NULL,'40000000-0000-4000-8000-000000000004');
 PERFORM public.complete_mission(m.id);
 SELECT * INTO p FROM public.travel_progress WHERE user_id=auth.uid();
 IF p.current_energy<>10 OR p.journey_energy_used<>10 OR (SELECT count(*) FROM public.user_checkpoint_progress WHERE status='completed')<>1 THEN RAISE EXCEPTION 'journey failed'; END IF;
 IF (SELECT count(*) FROM public.unlocked_landmarks)<>1 OR (SELECT count(*) FROM public.unlocked_foods)<>1 THEN RAISE EXCEPTION 'rewards failed'; END IF;
 j:=public.save_journal_with_tags('daily',jsonb_build_object('content','entry A','checkin_id',c.id,'mood','good'),ARRAY['Gia đình',' Bình yên ','gia ĐÌNH'],NULL);
 IF NOT EXISTS(SELECT 1 FROM public.daily_journals WHERE journal_id=j AND content='entry A') THEN RAISE EXCEPTION 'journal failed'; END IF;
 IF (SELECT count(*) FROM public.journal_tag_assignments WHERE journal_id=j)<>2 THEN RAISE EXCEPTION 'journal tags failed'; END IF;
 j2:=public.save_journal_with_tags('daily',jsonb_build_object('content','entry A updated'),ARRAY[]::text[],NULL);
 IF j2<>j OR (SELECT count(*) FROM public.daily_journals WHERE entry_date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)<>1 THEN RAISE EXCEPTION 'daily journal uniqueness failed'; END IF;
 media_path:=auth.uid()::text||'/'||j::text||'/entry.png';
 INSERT INTO storage.objects(id,bucket_id,name,owner_id) VALUES('50000000-0000-4000-8000-000000000001','journal-media',media_path,auth.uid()::text);
 media_id:=public.attach_journal_media(j,media_path,'image',NULL);
 PERFORM public.update_journal_media_transform(media_id,0.2,-0.1,1.75,1.2);
 IF NOT EXISTS(SELECT 1 FROM public.journal_media WHERE id=media_id AND position_x=0.2 AND position_y=-0.1 AND display_scale=1.75 AND rotation_radians=1.2) THEN RAISE EXCEPTION 'media transform failed'; END IF;
 PERFORM set_config('app.test.journal_a',j::text,true); PERFORM set_config('app.test.checkin_a',c.id::text,true);
 PERFORM set_config('app.test.media_a',media_id::text,true);
END $$;
RESET ROLE;
UPDATE public.user_missions
SET start_at=(((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date-1)::timestamp+time '09:00') AT TIME ZONE 'Asia/Ho_Chi_Minh',
    due_at=(((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date-1)::timestamp+time '10:00') AT TIME ZONE 'Asia/Ho_Chi_Minh',
    occurrence_key='series:'||current_setting('app.test.daily_series')||':'||(((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date-1)::text)
WHERE id=current_setting('app.test.daily_mission')::uuid;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE series uuid:=current_setting('app.test.daily_series')::uuid; refreshed integer;
BEGIN
 SELECT public.refresh_scheduled_missions() INTO refreshed;
 IF refreshed<>1 THEN RAISE EXCEPTION 'daily refresh did not materialize exactly once'; END IF;
 IF (SELECT count(*) FROM public.user_missions WHERE recurrence_series_id=series AND (start_at AT TIME ZONE 'Asia/Ho_Chi_Minh')::date=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date)<>1 THEN RAISE EXCEPTION 'daily occurrence for today missing'; END IF;
 IF (SELECT status FROM public.user_missions WHERE id=current_setting('app.test.daily_mission')::uuid)<>'expired' THEN RAISE EXCEPTION 'missed mission was not expired'; END IF;
 IF public.refresh_scheduled_missions()<>0 THEN RAISE EXCEPTION 'daily refresh is not idempotent'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',true);
DO $$
DECLARE j uuid:=current_setting('app.test.journal_a')::uuid; ca uuid:=current_setting('app.test.checkin_a')::uuid; media_id uuid:=current_setting('app.test.media_a')::uuid; blocked boolean:=false;
BEGIN
 PERFORM public.upsert_daily_checkin('okay',3,NULL);
 IF EXISTS(SELECT 1 FROM public.journals WHERE id=j) THEN RAISE EXCEPTION 'RLS leak'; END IF;
 BEGIN PERFORM public.save_journal_with_tags('daily',jsonb_build_object('content','bad','checkin_id',ca),ARRAY[]::text[],NULL);
 EXCEPTION WHEN check_violation OR raise_exception THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'cross-user relation accepted'; END IF;
 blocked:=false;
 BEGIN PERFORM public.update_journal_media_transform(media_id,0,0,1,0);
 EXCEPTION WHEN insufficient_privilege OR raise_exception THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'cross-user media transform accepted'; END IF;
 blocked:=false;
 BEGIN PERFORM public.set_journal_tags(j,ARRAY['stolen']);
 EXCEPTION WHEN insufficient_privilege OR raise_exception THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'cross-user tag assignment accepted'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE j uuid;
BEGIN
 j:=public.save_journal_with_tags('yearly','{"year":2026,"goals":[{"title":"Goal"}],"highlights":[{"title":"Moment"}],"lessons":[{"content":"Lesson"}]}'::jsonb,ARRAY[]::text[],NULL);
 IF (SELECT count(*) FROM public.yearly_goals WHERE yearly_journal_id=j)<>1 OR (SELECT count(*) FROM public.yearly_highlights WHERE yearly_journal_id=j)<>1 OR (SELECT count(*) FROM public.yearly_lessons WHERE yearly_journal_id=j)<>1 THEN RAISE EXCEPTION 'yearly save failed'; END IF;
 j:=public.save_journal_with_tags('future_letter',jsonb_build_object('content','Readable now','deliver_at',now()+interval '1 hour'),ARRAY[]::text[],NULL);
 IF (SELECT content FROM public.future_letters WHERE journal_id=j)<>'Readable now' THEN RAISE EXCEPTION 'future read failed'; END IF;
 PERFORM public.open_future_letter(j);
 IF (SELECT status FROM public.future_letters WHERE journal_id=j)<>'opened' THEN RAISE EXCEPTION 'future open failed'; END IF;
 PERFORM set_config('app.test.letter',j::text,true);
END $$;
RESET ROLE;
UPDATE public.future_letters SET written_at=now()-interval '2 hours',deliver_at=now()-interval '1 minute' WHERE journal_id=current_setting('app.test.letter')::uuid;
SELECT muse_private.process_due_letters();
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE j uuid:=current_setting('app.test.letter')::uuid; blocked boolean:=false;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.notifications WHERE journal_id=j) THEN RAISE EXCEPTION 'notification failed'; END IF;
 PERFORM public.soft_delete_journal(j);
 IF EXISTS(SELECT 1 FROM public.journals WHERE id=j) THEN RAISE EXCEPTION 'soft delete visibility failed'; END IF;
 UPDATE public.profiles SET display_name='Updated A' WHERE id=auth.uid();
 UPDATE public.user_settings SET cloud_name='Cloud A',theme_mode='dark',sound_enabled=false,notification_enabled=false WHERE user_id=auth.uid();
 IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE display_name='Updated A') OR NOT EXISTS(SELECT 1 FROM public.user_settings WHERE cloud_name='Cloud A' AND theme_mode='dark' AND NOT sound_enabled AND NOT notification_enabled) THEN RAISE EXCEPTION 'settings update failed'; END IF;
 BEGIN UPDATE public.profiles SET account_status='suspended' WHERE id=auth.uid();
 EXCEPTION WHEN insufficient_privilege THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'protected profile column accepted'; END IF;
END $$;
SELECT public.request_account_deletion();
RESET ROLE;
DO $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.account_deletion_requests WHERE user_id='10000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'account deletion request missing'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id='10000000-0000-4000-8000-000000000001' AND account_status='deleted' AND deleted_at IS NOT NULL) THEN RAISE EXCEPTION 'account not disabled'; END IF;
END $$;
ROLLBACK;
