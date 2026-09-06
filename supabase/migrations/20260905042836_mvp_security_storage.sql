-- Replace broad client grants with read access and explicit safe edits.
DROP POLICY "profiles_select_own" ON public."profiles";
DROP POLICY "profiles_update_own" ON public."profiles";
DROP POLICY "settings_all_own" ON public."user_settings";
DROP POLICY "checkins_all_own" ON public."daily_checkins";
DROP POLICY "journals_all_own" ON public."journals";
DROP POLICY "yearly_journals_all_own" ON public."yearly_journals";
DROP POLICY "journal_tags_all_own" ON public."journal_tags";
DROP POLICY "user_missions_all_own" ON public."user_missions";
DROP POLICY "travel_progress_all_own" ON public."travel_progress";
DROP POLICY "checkpoint_progress_all_own" ON public."user_checkpoint_progress";
DROP POLICY "travel_events_all_own" ON public."travel_events";
DROP POLICY "unlocked_provinces_all_own" ON public."unlocked_provinces";
DROP POLICY "unlocked_landmarks_all_own" ON public."unlocked_landmarks";
DROP POLICY "unlocked_foods_all_own" ON public."unlocked_foods";
DROP POLICY "unlocked_items_all_own" ON public."unlocked_province_items";
DROP POLICY "energy_transactions_select_own" ON public."energy_transactions";
DROP POLICY "daily_journals_all_own" ON public."daily_journals";
DROP POLICY "future_letters_all_own" ON public."future_letters";
DROP POLICY "journal_media_all_own" ON public."journal_media";
DROP POLICY "yearly_goals_all_own" ON public."yearly_goals";
DROP POLICY "yearly_highlights_all_own" ON public."yearly_highlights";
DROP POLICY "yearly_lessons_all_own" ON public."yearly_lessons";
DROP POLICY "journal_tag_assignments_all_own" ON public."journal_tag_assignments";
DROP POLICY "mission_templates_read" ON public."mission_templates";
DROP POLICY "provinces_read" ON public."provinces";
DROP POLICY "landmarks_read" ON public."landmarks";
DROP POLICY "foods_read" ON public."foods";
DROP POLICY "province_items_read" ON public."province_items";
DROP POLICY "province_checkpoints_read" ON public."province_checkpoints";
DROP POLICY "checkpoint_rewards_read" ON public."checkpoint_rewards";

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
REVOKE SELECT ON public.storage_cleanup_jobs,public.account_deletion_requests FROM authenticated;
CREATE POLICY mvp_read ON public.mission_templates FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND is_active);
CREATE POLICY mvp_read ON public.provinces FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND is_active);
CREATE POLICY mvp_read ON public.landmarks FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND is_active);
CREATE POLICY mvp_read ON public.foods FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND is_active);
CREATE POLICY mvp_read ON public.province_items FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND is_active);
CREATE POLICY mvp_read ON public.province_checkpoints FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND is_active);
CREATE POLICY mvp_read ON public.checkpoint_rewards FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()));
CREATE POLICY mvp_own ON public.user_settings FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.daily_checkins FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()) AND deleted_at IS NULL);
CREATE POLICY mvp_own ON public.user_missions FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()) AND deleted_at IS NULL);
CREATE POLICY mvp_own ON public.travel_progress FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.user_checkpoint_progress FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.travel_events FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.unlocked_provinces FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.unlocked_landmarks FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.unlocked_foods FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.unlocked_province_items FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.energy_transactions FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.daily_visits FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));
CREATE POLICY mvp_own ON public.notifications FOR SELECT TO authenticated USING ((SELECT muse_private.active_user()) AND user_id=(SELECT auth.uid()));

CREATE POLICY mvp_own ON public.profiles FOR SELECT TO authenticated USING(id=(SELECT auth.uid()) AND (SELECT muse_private.active_user()));
CREATE POLICY mvp_profile_edit ON public.profiles FOR UPDATE TO authenticated USING(id=(SELECT auth.uid()) AND (SELECT muse_private.active_user())) WITH CHECK(id=(SELECT auth.uid()));
GRANT UPDATE(display_name) ON public.profiles TO authenticated;
CREATE POLICY mvp_settings_edit ON public.user_settings FOR UPDATE TO authenticated USING(user_id=(SELECT auth.uid()) AND (SELECT muse_private.active_user())) WITH CHECK(user_id=(SELECT auth.uid()));
GRANT UPDATE(cloud_name,theme_mode,language_code,sound_enabled,background_music_enabled,notification_enabled,daily_reminder_time,biometric_lock_enabled,ai_personalization_enabled) ON public.user_settings TO authenticated;
CREATE POLICY mvp_journal_read ON public.journals FOR SELECT TO authenticated USING(user_id=(SELECT auth.uid()) AND deleted_at IS NULL AND (SELECT muse_private.active_user()));
CREATE POLICY mvp_tags ON public.journal_tags FOR ALL TO authenticated USING(user_id=(SELECT auth.uid()) AND deleted_at IS NULL AND (SELECT muse_private.active_user())) WITH CHECK(user_id=(SELECT auth.uid()) AND (SELECT muse_private.active_user()));
GRANT INSERT(user_id,name,icon_name,color_value),UPDATE(name,icon_name,color_value) ON public.journal_tags TO authenticated;
CREATE POLICY mvp_journal_read ON public.daily_journals FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.journals j WHERE j.id=daily_journals.journal_id));
CREATE POLICY mvp_journal_read ON public.yearly_journals FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.journals j WHERE j.id=yearly_journals.journal_id));
CREATE POLICY mvp_journal_read ON public.future_letters FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.journals j WHERE j.id=future_letters.journal_id));
CREATE POLICY mvp_journal_read ON public.journal_media FOR SELECT TO authenticated USING (deleted_at IS NULL AND EXISTS(SELECT 1 FROM public.journals j WHERE j.id=journal_media.journal_id));
CREATE POLICY mvp_journal_read ON public.yearly_goals FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.yearly_journals y WHERE y.journal_id=yearly_goals.yearly_journal_id));
CREATE POLICY mvp_journal_read ON public.yearly_highlights FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.yearly_journals y WHERE y.journal_id=yearly_highlights.yearly_journal_id));
CREATE POLICY mvp_journal_read ON public.yearly_lessons FOR SELECT TO authenticated USING (EXISTS(SELECT 1 FROM public.yearly_journals y WHERE y.journal_id=yearly_lessons.yearly_journal_id));

CREATE POLICY mvp_assignment ON public.journal_tag_assignments FOR ALL TO authenticated
 USING(EXISTS(SELECT 1 FROM public.journals j WHERE j.id=journal_id) AND EXISTS(SELECT 1 FROM public.journal_tags t WHERE t.id=tag_id))
 WITH CHECK(EXISTS(SELECT 1 FROM public.journals j WHERE j.id=journal_id) AND EXISTS(SELECT 1 FROM public.journal_tags t WHERE t.id=tag_id));
GRANT INSERT(journal_id,tag_id),DELETE ON public.journal_tag_assignments TO authenticated;
CREATE POLICY mvp_mark_viewed ON public.unlocked_landmarks FOR UPDATE TO authenticated USING(user_id=(SELECT auth.uid()) AND (SELECT muse_private.active_user())) WITH CHECK(user_id=(SELECT auth.uid()));
GRANT UPDATE(is_viewed) ON public.unlocked_landmarks TO authenticated;
CREATE POLICY mvp_mark_viewed ON public.unlocked_foods FOR UPDATE TO authenticated USING(user_id=(SELECT auth.uid()) AND (SELECT muse_private.active_user())) WITH CHECK(user_id=(SELECT auth.uid()));
GRANT UPDATE(is_viewed) ON public.unlocked_foods TO authenticated;
CREATE POLICY mvp_mark_viewed ON public.unlocked_province_items FOR UPDATE TO authenticated USING(user_id=(SELECT auth.uid()) AND (SELECT muse_private.active_user())) WITH CHECK(user_id=(SELECT auth.uid()));
GRANT UPDATE(is_viewed) ON public.unlocked_province_items TO authenticated;

INSERT INTO storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
VALUES('journal-media','journal-media',false,52428800,ARRAY['image/jpeg','image/png','image/webp','image/heic','audio/mpeg','audio/mp4','audio/aac','audio/wav','audio/x-m4a','video/mp4','video/quicktime','application/pdf'])
ON CONFLICT(id) DO NOTHING;

CREATE FUNCTION muse_private.can_access_journal_object(path text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT muse_private.active_user() AND split_part(path,'/',1)=auth.uid()::text
 AND EXISTS(SELECT 1 FROM public.journals j WHERE j.id::text=split_part(path,'/',2) AND j.user_id=auth.uid() AND j.deleted_at IS NULL)
 AND length(split_part(path,'/',3))>0
 AND NOT EXISTS(SELECT 1 FROM public.storage_cleanup_jobs q WHERE q.bucket_id='journal-media' AND q.object_path=path)
$$;
CREATE POLICY muse_journal_object_read ON storage.objects FOR SELECT TO authenticated
 USING(bucket_id='journal-media' AND muse_private.can_access_journal_object(name));
CREATE POLICY muse_journal_object_insert ON storage.objects FOR INSERT TO authenticated
 WITH CHECK(bucket_id='journal-media' AND muse_private.can_access_journal_object(name));
-- No overwrite/direct deletion: use unique object names and the cleanup queue.

CREATE FUNCTION public.attach_journal_media(p_journal_id uuid,p_path text,p_type public.media_type,p_thumbnail text DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); mid uuid; prefix text:=u::text||'/'||p_journal_id::text||'/';
BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.journals WHERE id=p_journal_id AND user_id=u AND deleted_at IS NULL) THEN RAISE EXCEPTION 'Journal unavailable' USING ERRCODE='42501'; END IF;
 IF p_path IS NULL OR left(p_path,length(prefix))<>prefix OR NOT muse_private.can_access_journal_object(p_path)
 OR NOT EXISTS(SELECT 1 FROM storage.objects WHERE bucket_id='journal-media' AND name=p_path) THEN RAISE EXCEPTION 'Uploaded private object required'; END IF;
 IF p_thumbnail IS NOT NULL AND (left(p_thumbnail,length(prefix))<>prefix OR NOT muse_private.can_access_journal_object(p_thumbnail)
 OR NOT EXISTS(SELECT 1 FROM storage.objects WHERE bucket_id='journal-media' AND name=p_thumbnail)) THEN RAISE EXCEPTION 'Invalid thumbnail'; END IF;
 SELECT id INTO mid FROM public.journal_media WHERE journal_id=p_journal_id AND storage_bucket='journal-media' AND storage_path=p_path AND deleted_at IS NULL;
 IF mid IS NOT NULL THEN RETURN mid; END IF;
 INSERT INTO public.journal_media(journal_id,media_type,storage_bucket,storage_path,thumbnail_path,upload_status)
 VALUES(p_journal_id,p_type,'journal-media',p_path,p_thumbnail,'completed') RETURNING id INTO mid;
 RETURN mid;
END $$;

CREATE FUNCTION public.soft_delete_journal_media(p_media_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); m public.journal_media;
BEGIN
 SELECT jm.* INTO m FROM public.journal_media jm JOIN public.journals j ON j.id=jm.journal_id
 WHERE jm.id=p_media_id AND j.user_id=u AND j.deleted_at IS NULL FOR UPDATE OF jm;
 IF NOT FOUND THEN RAISE EXCEPTION 'Media unavailable'; END IF;
 UPDATE public.journal_media SET deleted_at=coalesce(deleted_at,now()) WHERE id=m.id;
 INSERT INTO public.storage_cleanup_jobs(user_id,journal_id,bucket_id,object_path,not_before)
 SELECT u,m.journal_id,'journal-media',p,now()+interval '30 days' FROM unnest(ARRAY[m.storage_path,m.thumbnail_path]) p WHERE p IS NOT NULL
 ON CONFLICT(bucket_id,object_path) DO NOTHING;
END $$;

-- Restore account bootstrap to recognize supported providers.
CREATE OR REPLACE FUNCTION public.handle_new_auth_user() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE provider text:=NEW.raw_app_meta_data->>'provider';
BEGIN
 INSERT INTO public.profiles(id,display_name,avatar_url,auth_provider)
 VALUES(NEW.id,coalesce(NEW.raw_user_meta_data->>'display_name',NEW.raw_user_meta_data->>'full_name'),NEW.raw_user_meta_data->>'avatar_url',
 CASE WHEN NEW.is_anonymous THEN 'anonymous'::public.auth_provider_type
 WHEN provider IN ('google','apple','email') THEN provider::public.auth_provider_type ELSE 'email'::public.auth_provider_type END)
 ON CONFLICT(id) DO NOTHING;
 INSERT INTO public.user_settings(user_id) VALUES(NEW.id) ON CONFLICT(user_id) DO NOTHING;
 INSERT INTO public.travel_progress(user_id) VALUES(NEW.id) ON CONFLICT(user_id) DO NOTHING;
 RETURN NEW;
END $$;

