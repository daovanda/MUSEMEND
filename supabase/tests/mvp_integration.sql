BEGIN;
DO $$
BEGIN
 IF to_regclass('public.provinces') IS NOT NULL OR to_regclass('public.province_checkpoints') IS NOT NULL THEN RAISE EXCEPTION 'legacy province tables still exposed'; END IF;
 IF to_regclass('public.destinations') IS NULL OR to_regclass('public.destination_checkpoints') IS NULL THEN RAISE EXCEPTION 'global destination tables missing'; END IF;
 IF to_regclass('public.destination_translations') IS NULL
    OR to_regclass('public.checkpoint_translations') IS NULL
    OR to_regclass('public.landmark_translations') IS NULL
    OR to_regclass('public.food_translations') IS NULL
    OR to_regclass('public.destination_item_translations') IS NULL
    OR to_regclass('public.mission_template_translations') IS NULL
    OR to_regclass('public.daily_quote_translations') IS NULL
 THEN RAISE EXCEPTION 'multilingual catalog tables missing'; END IF;
 IF (SELECT count(*) FROM public.supported_languages WHERE is_active)<>12 THEN RAISE EXCEPTION 'supported language catalog must contain 12 active rows'; END IF;
 IF muse_private.resolve_language_code('vi')<>'vi' OR muse_private.resolve_language_code('xx')<>'en' OR muse_private.resolve_language_code(NULL)<>'en' THEN RAISE EXCEPTION 'language fallback must resolve unsupported locales to English'; END IF;
 IF EXISTS(SELECT 1 FROM auth.users) THEN RAISE EXCEPTION 'development auth users were not reset'; END IF;
 IF EXISTS(SELECT 1 FROM public.destinations)
    OR EXISTS(SELECT 1 FROM public.destination_checkpoints)
    OR EXISTS(SELECT 1 FROM public.landmarks)
    OR EXISTS(SELECT 1 FROM public.foods)
    OR EXISTS(SELECT 1 FROM public.destination_items)
    OR EXISTS(SELECT 1 FROM public.mission_templates)
    OR EXISTS(SELECT 1 FROM public.daily_quotes)
 THEN RAISE EXCEPTION 'legacy application catalog was not reset'; END IF;
END $$;

-- Transaction-scoped fixtures keep domain/RLS/RPC coverage without restoring
-- any demo content after this test rolls back.
DO $$
DECLARE destination_id bigint; checkpoint_id bigint; landmark_id bigint; food_id bigint; item_id bigint;
BEGIN
 INSERT INTO public.destinations(code,name,description,country_code,destination_type,order_index)
 VALUES('test-destination','Test destination','Test-only route','VN','city',1)
 RETURNING id INTO destination_id;
 INSERT INTO public.destination_translations(destination_id,language_code,name,description)
 VALUES(destination_id,'en','Test destination','Test-only route'),(destination_id,'vi','Điểm đến thử nghiệm','Hành trình chỉ dùng trong test');
 INSERT INTO public.destination_checkpoints(destination_id,checkpoint_number,title,description,required_energy,order_index)
 VALUES(destination_id,1,'Test checkpoint','Test-only checkpoint',10,1)
 RETURNING id INTO checkpoint_id;
 INSERT INTO public.checkpoint_translations(checkpoint_id,language_code,title,description)
 VALUES(checkpoint_id,'en','Test checkpoint','Test-only checkpoint'),(checkpoint_id,'vi','Trạm thử nghiệm','Trạm chỉ dùng trong test');
 INSERT INTO public.landmarks(destination_id,code,name,description,order_index)
 VALUES(destination_id,'test-landmark','Test landmark','Test-only landmark',1)
 RETURNING id INTO landmark_id;
 INSERT INTO public.foods(destination_id,code,name,description,order_index)
 VALUES(destination_id,'test-food','Test food','Test-only food',1)
 RETURNING id INTO food_id;
 INSERT INTO public.destination_items(destination_id,code,name,item_type,description,order_index)
 VALUES(destination_id,'test-item','Test item','badge','Test-only item',1)
 RETURNING id INTO item_id;
 INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,landmark_id,order_index)
 VALUES(checkpoint_id,'landmark',landmark_id,1);
 INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,food_id,order_index)
 VALUES(checkpoint_id,'food',food_id,2);
 INSERT INTO public.checkpoint_rewards(checkpoint_id,reward_type,destination_item_id,order_index)
 VALUES(checkpoint_id,'destination_item',item_id,3);
END $$;

INSERT INTO public.mission_templates(code,title,description,mission_type,target_mood,default_energy_reward,estimated_minutes) VALUES
 ('demo-water','Uống một cốc nước','Nhiệm vụ khởi đầu dùng trong kiểm thử','daily','all',5,1),
 ('demo-walk','Đi bộ năm phút','Nhiệm vụ khởi đầu dùng trong kiểm thử','daily','all',5,5);
INSERT INTO public.mission_template_translations(mission_template_id,language_code,title,description)
SELECT id,'en',
 CASE code WHEN 'demo-water' THEN 'Drink a glass of water' ELSE 'Walk for five minutes' END,
 'Test starter mission'
FROM public.mission_templates;
INSERT INTO public.daily_quotes(rotation_order,topic,content) VALUES
 (1,'life','Câu nhắn thử nghiệm thứ nhất.'),
 (2,'life','Câu nhắn thử nghiệm thứ hai.');
INSERT INTO public.daily_quote_translations(quote_rotation_order,language_code,content) VALUES
 (1,'en','English fallback quote one.'),(1,'vi','Câu nhắn thử nghiệm thứ nhất.'),
 (2,'en','English fallback quote two.'),(2,'vi','Câu nhắn thử nghiệm thứ hai.');

DO $$
DECLARE quote_today record; quote_today_again record; quote_tomorrow record; today date:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
BEGIN
 SELECT * INTO quote_today FROM muse_private.daily_quote_for_date(today);
 SELECT * INTO quote_today_again FROM muse_private.daily_quote_for_date(today);
 SELECT * INTO quote_tomorrow FROM muse_private.daily_quote_for_date(today+1);
 IF quote_today.rotation_order IS NULL OR quote_today.rotation_order<>quote_today_again.rotation_order THEN RAISE EXCEPTION 'daily quote is not deterministic'; END IF;
 IF quote_today.rotation_order=quote_tomorrow.rotation_order THEN RAISE EXCEPTION 'daily quote did not change on the next day'; END IF;
END $$;
INSERT INTO auth.users(id,email,raw_user_meta_data,raw_app_meta_data) VALUES
 ('10000000-0000-4000-8000-000000000001','a@example.invalid','{"display_name":"A"}','{"provider":"email"}'),
 ('20000000-0000-4000-8000-000000000002','b@example.invalid','{"display_name":"B"}','{"provider":"email"}');
DO $$
BEGIN
 IF EXISTS(
  SELECT 1 FROM public.user_settings
  WHERE user_id IN (
    '10000000-0000-4000-8000-000000000001'::uuid,
    '20000000-0000-4000-8000-000000000002'::uuid
  ) AND theme_mode <> 'light'::public.theme_mode_type
 ) THEN RAISE EXCEPTION 'new account theme must default to light'; END IF;
END $$;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE c public.daily_checkins; c2 public.daily_checkins; v jsonb; m public.user_missions; scheduled public.user_missions; r jsonb; p public.travel_progress; j uuid; j2 uuid; media_id uuid; media_path text; starter_count integer; blocked boolean:=false; today date:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date; daily_quote record; daily_quote_vi record; daily_quote_unknown record;
BEGIN
 IF NOT EXISTS(
  SELECT 1 FROM public.profiles
  WHERE id=auth.uid() AND onboarding_completed_at IS NULL
 ) THEN RAISE EXCEPTION 'new account onboarding state is incorrect'; END IF;
 PERFORM public.complete_onboarding('An', 'ban_minh');
 IF NOT EXISTS(
  SELECT 1 FROM public.profiles
  WHERE id=auth.uid() AND display_name='An'
    AND preferred_address='ban_minh' AND onboarding_completed_at IS NOT NULL
 ) THEN RAISE EXCEPTION 'onboarding completion failed'; END IF;
 SELECT * INTO daily_quote FROM public.get_daily_quote();
 IF daily_quote.rotation_order IS NULL OR daily_quote.quote_date<>today THEN RAISE EXCEPTION 'authenticated daily quote RPC failed'; END IF;
 SELECT * INTO daily_quote_vi FROM public.get_daily_quote('vi');
 SELECT * INTO daily_quote_unknown FROM public.get_daily_quote('xx');
 IF daily_quote_vi.content NOT LIKE 'Câu nhắn thử nghiệm%' THEN RAISE EXCEPTION 'Vietnamese quote source was not selected'; END IF;
 IF daily_quote_unknown.content NOT LIKE 'English fallback quote%' THEN RAISE EXCEPTION 'unsupported quote locale did not fall back to English'; END IF;
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
