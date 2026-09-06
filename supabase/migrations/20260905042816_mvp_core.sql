-- Server-owned rewards, daily check-in, visits/streak and consistent relations.
CREATE SCHEMA IF NOT EXISTS muse_private;
REVOKE ALL ON SCHEMA muse_private FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA muse_private TO authenticated, service_role;

CREATE FUNCTION muse_private.require_user() RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE u uuid := auth.uid();
BEGIN
 IF u IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='42501'; END IF;
 PERFORM 1 FROM public.profiles WHERE id=u AND account_status='active' AND deleted_at IS NULL FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Account unavailable' USING ERRCODE='42501'; END IF;
 RETURN u;
END $$;

CREATE FUNCTION muse_private.active_user() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id=auth.uid() AND account_status='active' AND deleted_at IS NULL)
$$;

ALTER TABLE public.daily_checkins ADD CONSTRAINT daily_checkins_one_per_day UNIQUE(user_id,checkin_date);
ALTER TABLE public.daily_checkins ADD CONSTRAINT checkin_mood_matches_score CHECK (
 mood_score=CASE mood WHEN 'awful' THEN 1 WHEN 'sad' THEN 2 WHEN 'okay' THEN 3 WHEN 'good' THEN 4 WHEN 'great' THEN 5 END);
ALTER TABLE public.daily_journals ALTER COLUMN entry_date SET DEFAULT ((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date);
ALTER TABLE public.travel_progress ADD COLUMN journey_energy_used bigint NOT NULL DEFAULT 0 CHECK(journey_energy_used>=0);
ALTER TABLE public.province_checkpoints ADD CONSTRAINT positive_checkpoint_energy CHECK(required_energy>0) NOT VALID;
-- Validate immediately: preflight confirmed empty catalog.
ALTER TABLE public.province_checkpoints VALIDATE CONSTRAINT positive_checkpoint_energy;

CREATE TABLE public.daily_visits(
 user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 visit_date date NOT NULL DEFAULT ((now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date),
 first_opened_at timestamptz NOT NULL DEFAULT now(),
 PRIMARY KEY(user_id,visit_date)
);
ALTER TABLE public.daily_visits ENABLE ROW LEVEL SECURITY;
CREATE TABLE public.notifications(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
 journal_id uuid REFERENCES public.journals(id) ON DELETE CASCADE,
 kind text NOT NULL CHECK(kind='future_letter_due'),
 scheduled_for timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 read_at timestamptz,
 UNIQUE(journal_id,kind,scheduled_for)
);
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE INDEX notifications_user_time_idx ON public.notifications(user_id,created_at DESC);
CREATE TABLE public.account_deletion_requests(
 user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
 requested_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.account_deletion_requests ENABLE ROW LEVEL SECURITY;

CREATE FUNCTION muse_private.validate_relations() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE owner_id uuid;
BEGIN
 IF TG_TABLE_NAME='daily_journals' THEN
  SELECT user_id INTO owner_id FROM public.journals WHERE id=NEW.journal_id;
  IF NEW.checkin_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.daily_checkins WHERE id=NEW.checkin_id AND user_id=owner_id) THEN
   RAISE EXCEPTION 'Check-in must belong to journal owner' USING ERRCODE='23514';
  END IF;
 ELSIF TG_TABLE_NAME='user_missions' THEN
  IF NEW.source_checkin_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.daily_checkins WHERE id=NEW.source_checkin_id AND user_id=NEW.user_id) THEN
   RAISE EXCEPTION 'Check-in must belong to mission owner' USING ERRCODE='23514';
  END IF;
 ELSIF TG_TABLE_NAME='travel_progress' THEN
  IF NEW.current_checkpoint_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.province_checkpoints WHERE id=NEW.current_checkpoint_id AND province_id=NEW.current_province_id) THEN
   RAISE EXCEPTION 'Checkpoint must belong to current province' USING ERRCODE='23514';
  END IF;
 ELSIF TG_TABLE_NAME='journals' THEN
  IF NEW.journal_type IS DISTINCT FROM OLD.journal_type OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN
   RAISE EXCEPTION 'Journal type and owner are immutable' USING ERRCODE='23514';
  END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER daily_journal_owner BEFORE INSERT OR UPDATE ON public.daily_journals FOR EACH ROW EXECUTE FUNCTION muse_private.validate_relations();
CREATE TRIGGER mission_checkin_owner BEFORE INSERT OR UPDATE ON public.user_missions FOR EACH ROW EXECUTE FUNCTION muse_private.validate_relations();
CREATE TRIGGER travel_checkpoint_province BEFORE INSERT OR UPDATE ON public.travel_progress FOR EACH ROW EXECUTE FUNCTION muse_private.validate_relations();
CREATE TRIGGER journal_immutable_identity BEFORE UPDATE ON public.journals FOR EACH ROW EXECUTE FUNCTION muse_private.validate_relations();

CREATE FUNCTION public.upsert_daily_checkin(p_mood public.mood_type,p_energy_level integer DEFAULT NULL,p_note text DEFAULT NULL)
RETURNS public.daily_checkins LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); r public.daily_checkins;
BEGIN
 INSERT INTO public.daily_checkins(user_id,mood,mood_score,energy_level,note_short)
 VALUES(u,p_mood,CASE p_mood WHEN 'awful' THEN 1 WHEN 'sad' THEN 2 WHEN 'okay' THEN 3 WHEN 'good' THEN 4 WHEN 'great' THEN 5 END,p_energy_level::smallint,p_note)
 ON CONFLICT(user_id,checkin_date) DO UPDATE SET mood=EXCLUDED.mood,mood_score=EXCLUDED.mood_score,energy_level=EXCLUDED.energy_level,note_short=EXCLUDED.note_short,deleted_at=NULL
 RETURNING * INTO r;
 RETURN r;
END $$;

CREATE FUNCTION public.record_app_open() RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); today date:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date; streak integer;
BEGIN
 INSERT INTO public.daily_visits(user_id,visit_date) VALUES(u,today) ON CONFLICT DO NOTHING;
 SELECT count(*)::integer INTO streak FROM (
  SELECT visit_date,row_number() OVER(ORDER BY visit_date DESC)::integer rn FROM public.daily_visits WHERE user_id=u AND visit_date<=today
 ) d WHERE visit_date=today-(rn-1);
 RETURN jsonb_build_object('visit_date',today,'streak',streak);
END $$;

ALTER TABLE public.user_missions ADD COLUMN occurrence_key text;
CREATE UNIQUE INDEX user_missions_occurrence_unique ON public.user_missions(user_id,occurrence_key) WHERE occurrence_key IS NOT NULL;
CREATE FUNCTION public.create_mission(p_template_id bigint DEFAULT NULL,p_title text DEFAULT NULL,p_description text DEFAULT NULL,p_checkin_id uuid DEFAULT NULL,p_request_id uuid DEFAULT NULL)
RETURNS public.user_missions LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); t public.mission_templates; r public.user_missions;
 k text; due timestamptz; start_date date:=(now() AT TIME ZONE 'Asia/Ho_Chi_Minh')::date;
BEGIN
 IF p_template_id IS NULL THEN
  IF p_title IS NULL OR length(btrim(p_title)) NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'Title must contain 1-200 characters'; END IF;
  IF p_checkin_id IS NOT NULL THEN RAISE EXCEPTION 'Custom mission cannot impersonate a mood mission'; END IF;
  k:='custom:'||coalesce(p_request_id,gen_random_uuid())::text;
  INSERT INTO public.user_missions(user_id,source_type,mission_type,title_snapshot,description_snapshot,energy_reward,occurrence_key)
  VALUES(u,'user_created','custom',btrim(p_title),p_description,5,k)
  ON CONFLICT(user_id,occurrence_key) WHERE occurrence_key IS NOT NULL DO NOTHING;
 ELSE
  SELECT * INTO t FROM public.mission_templates WHERE id=p_template_id AND is_active;
  IF NOT FOUND THEN RAISE EXCEPTION 'Template unavailable'; END IF;
  IF p_checkin_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.daily_checkins WHERE id=p_checkin_id AND user_id=u AND deleted_at IS NULL) THEN RAISE EXCEPTION 'Check-in unavailable'; END IF;
  IF t.target_mood<>'all' AND NOT EXISTS(SELECT 1 FROM public.daily_checkins WHERE user_id=u AND checkin_date=start_date AND deleted_at IS NULL AND mood::text=t.target_mood::text) THEN RAISE EXCEPTION 'Template does not match today mood'; END IF;
  CASE t.mission_type
   WHEN 'daily' THEN due:=((start_date+1)::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh'); k:=start_date::text;
   WHEN 'weekly' THEN start_date:=date_trunc('week',start_date::timestamp)::date; due:=((start_date+7)::timestamp AT TIME ZONE 'Asia/Ho_Chi_Minh'); k:=start_date::text;
   WHEN 'monthly' THEN start_date:=date_trunc('month',start_date::timestamp)::date; due:=((start_date::timestamp+interval '1 month') AT TIME ZONE 'Asia/Ho_Chi_Minh'); k:=start_date::text;
   WHEN 'yearly' THEN start_date:=date_trunc('year',start_date::timestamp)::date; due:=((start_date::timestamp+interval '1 year') AT TIME ZONE 'Asia/Ho_Chi_Minh'); k:=start_date::text;
   ELSE k:='once';
  END CASE;
  k:='template:'||t.id::text||':'||k;
  INSERT INTO public.user_missions(user_id,template_id,source_type,source_checkin_id,mission_type,title_snapshot,description_snapshot,energy_reward,due_at,occurrence_key)
  VALUES(u,t.id,CASE WHEN p_checkin_id IS NULL THEN 'system'::public.mission_source_type ELSE 'mood_checkin'::public.mission_source_type END,p_checkin_id,t.mission_type,t.title,t.description,t.default_energy_reward,due,k)
  ON CONFLICT(user_id,occurrence_key) WHERE occurrence_key IS NOT NULL DO NOTHING;
 END IF;
 SELECT * INTO r FROM public.user_missions WHERE user_id=u AND occurrence_key=k;
 RETURN r;
END $$;

CREATE FUNCTION public.update_custom_mission(p_mission_id uuid,p_title text,p_description text DEFAULT NULL)
RETURNS public.user_missions LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); r public.user_missions;
BEGIN
 IF p_title IS NULL OR length(btrim(p_title)) NOT BETWEEN 1 AND 200 THEN RAISE EXCEPTION 'Invalid title'; END IF;
 UPDATE public.user_missions SET title_snapshot=btrim(p_title),description_snapshot=p_description
 WHERE id=p_mission_id AND user_id=u AND source_type='user_created' AND status IN ('pending','in_progress') AND deleted_at IS NULL RETURNING * INTO r;
 IF NOT FOUND THEN RAISE EXCEPTION 'Editable custom mission not found'; END IF;
 RETURN r;
END $$;

CREATE FUNCTION public.skip_mission(p_mission_id uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user();
BEGIN
 UPDATE public.user_missions SET status='skipped' WHERE id=p_mission_id AND user_id=u AND status IN ('pending','in_progress') AND deleted_at IS NULL;
 IF NOT FOUND THEN RAISE EXCEPTION 'Pending mission not found'; END IF;
END $$;
