BEGIN;
INSERT INTO auth.users(id,email,raw_user_meta_data,raw_app_meta_data) VALUES
 ('10000000-0000-4000-8000-000000000001','a@example.invalid','{"display_name":"A"}','{"provider":"email"}'),
 ('20000000-0000-4000-8000-000000000002','b@example.invalid','{"display_name":"B"}','{"provider":"email"}');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE c public.daily_checkins; c2 public.daily_checkins; v jsonb; m public.user_missions; r jsonb; p public.travel_progress; j uuid;
BEGIN
 SELECT * INTO c FROM public.upsert_daily_checkin('sad',2,'first');
 SELECT * INTO c2 FROM public.upsert_daily_checkin('good',4,'edited');
 IF c.id<>c2.id OR c2.mood<>'good' OR (SELECT count(*) FROM public.daily_checkins)<>1 THEN RAISE EXCEPTION 'check-in failed'; END IF;
 SELECT public.record_app_open() INTO v; PERFORM public.record_app_open();
 IF (v->>'streak')::int<>1 OR (SELECT count(*) FROM public.daily_visits)<>1 THEN RAISE EXCEPTION 'streak failed'; END IF;
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
 PERFORM set_config('app.test.journal_a',j::text,true); PERFORM set_config('app.test.checkin_a',c.id::text,true);
END $$;
SELECT set_config('request.jwt.claim.sub','20000000-0000-4000-8000-000000000002',true);
DO $$
DECLARE j uuid:=current_setting('app.test.journal_a')::uuid; ca uuid:=current_setting('app.test.checkin_a')::uuid; blocked boolean:=false;
BEGIN
 PERFORM public.upsert_daily_checkin('okay',3,NULL);
 IF EXISTS(SELECT 1 FROM public.journals WHERE id=j) THEN RAISE EXCEPTION 'RLS leak'; END IF;
 BEGIN PERFORM public.save_journal('daily',jsonb_build_object('content','bad','checkin_id',ca),NULL);
 EXCEPTION WHEN check_violation OR raise_exception THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'cross-user relation accepted'; END IF;
 blocked:=false;
 BEGIN PERFORM public.set_journal_tags(j,ARRAY['stolen']);
 EXCEPTION WHEN insufficient_privilege OR raise_exception THEN blocked:=true; END;
 IF NOT blocked THEN RAISE EXCEPTION 'cross-user tag assignment accepted'; END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','10000000-0000-4000-8000-000000000001',true);
DO $$
DECLARE j uuid;
BEGIN
 j:=public.save_journal('yearly','{"year":2026,"goals":[{"title":"Goal"}],"highlights":[{"title":"Moment"}],"lessons":[{"content":"Lesson"}]}'::jsonb,NULL);
 IF (SELECT count(*) FROM public.yearly_goals WHERE yearly_journal_id=j)<>1 OR (SELECT count(*) FROM public.yearly_highlights WHERE yearly_journal_id=j)<>1 OR (SELECT count(*) FROM public.yearly_lessons WHERE yearly_journal_id=j)<>1 THEN RAISE EXCEPTION 'yearly save failed'; END IF;
 j:=public.save_journal('future_letter',jsonb_build_object('content','Readable now','deliver_at',now()+interval '1 hour'),NULL);
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
