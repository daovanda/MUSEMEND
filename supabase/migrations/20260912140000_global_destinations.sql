-- Generalize the original Vietnam-specific journey schema without replacing
-- rows. ALTER ... RENAME preserves IDs, foreign-key relationships, RLS and
-- grants while exposing vocabulary that matches the global catalog.

ALTER TYPE public.region_type RENAME TO vietnam_region_type;
ALTER TYPE public.province_item_type RENAME TO destination_item_type;
ALTER TYPE public.checkpoint_reward_type RENAME VALUE 'province_item' TO 'destination_item';
ALTER TYPE public.travel_event_type RENAME VALUE 'province_unlocked' TO 'destination_unlocked';
ALTER TYPE public.travel_event_type RENAME VALUE 'province_completed' TO 'destination_completed';

ALTER TABLE public.provinces RENAME TO destinations;
ALTER TABLE public.province_checkpoints RENAME TO destination_checkpoints;
ALTER TABLE public.province_items RENAME TO destination_items;
ALTER TABLE public.unlocked_provinces RENAME TO unlocked_destinations;
ALTER TABLE public.unlocked_province_items RENAME TO unlocked_destination_items;

ALTER TABLE public.destinations RENAME COLUMN region TO vietnam_region;
ALTER TABLE public.destination_checkpoints RENAME COLUMN province_id TO destination_id;
ALTER TABLE public.destination_items RENAME COLUMN province_id TO destination_id;
ALTER TABLE public.landmarks RENAME COLUMN province_id TO destination_id;
ALTER TABLE public.foods RENAME COLUMN province_id TO destination_id;
ALTER TABLE public.checkpoint_rewards RENAME COLUMN province_item_id TO destination_item_id;
ALTER TABLE public.travel_events RENAME COLUMN province_id TO destination_id;
ALTER TABLE public.travel_progress RENAME COLUMN current_province_id TO current_destination_id;
ALTER TABLE public.unlocked_destinations RENAME COLUMN province_id TO destination_id;
ALTER TABLE public.unlocked_destination_items RENAME COLUMN province_item_id TO destination_item_id;

-- Rows from the original MVP catalog predate global metadata. They are all
-- Vietnamese destinations, so backfill them before making country mandatory.
UPDATE public.destinations
SET country_code = 'VN',
    destination_type = CASE code
      WHEN 'demo-ha-noi' THEN 'city'
      WHEN 'demo-da-nang' THEN 'city'
      WHEN 'demo-lam-dong' THEN 'province'
      ELSE destination_type
    END
WHERE country_code IS NULL;

ALTER TABLE public.destinations ALTER COLUMN country_code SET NOT NULL;
ALTER TABLE public.destinations ALTER COLUMN destination_type DROP DEFAULT;

ALTER SEQUENCE public.provinces_id_seq RENAME TO destinations_id_seq;
ALTER SEQUENCE public.province_checkpoints_id_seq RENAME TO destination_checkpoints_id_seq;
ALTER SEQUENCE public.province_items_id_seq RENAME TO destination_items_id_seq;

ALTER TABLE public.destinations RENAME CONSTRAINT provinces_pkey TO destinations_pkey;
ALTER TABLE public.destinations RENAME CONSTRAINT provinces_code_key TO destinations_code_key;
ALTER TABLE public.destinations RENAME CONSTRAINT provinces_name_key TO destinations_name_key;
ALTER TABLE public.destinations RENAME CONSTRAINT provinces_country_code_check TO destinations_country_code_check;
ALTER TABLE public.destinations RENAME CONSTRAINT provinces_destination_type_check TO destinations_type_check;

ALTER TABLE public.destination_checkpoints RENAME CONSTRAINT province_checkpoints_pkey TO destination_checkpoints_pkey;
ALTER TABLE public.destination_checkpoints RENAME CONSTRAINT province_checkpoints_province_id_fkey TO destination_checkpoints_destination_id_fkey;
ALTER TABLE public.destination_checkpoints RENAME CONSTRAINT province_checkpoints_province_id_checkpoint_number_key TO destination_checkpoints_destination_number_key;
ALTER TABLE public.destination_checkpoints RENAME CONSTRAINT province_checkpoints_checkpoint_number_check TO destination_checkpoints_number_check;
ALTER TABLE public.destination_checkpoints RENAME CONSTRAINT province_checkpoints_required_energy_check TO destination_checkpoints_energy_check;

ALTER TABLE public.destination_items RENAME CONSTRAINT province_items_pkey TO destination_items_pkey;
ALTER TABLE public.destination_items RENAME CONSTRAINT province_items_code_key TO destination_items_code_key;
ALTER TABLE public.destination_items RENAME CONSTRAINT province_items_province_id_code_key TO destination_items_destination_code_key;
ALTER TABLE public.destination_items RENAME CONSTRAINT province_items_province_id_fkey TO destination_items_destination_id_fkey;

ALTER TABLE public.unlocked_destinations RENAME CONSTRAINT unlocked_provinces_pkey TO unlocked_destinations_pkey;
ALTER TABLE public.unlocked_destinations RENAME CONSTRAINT unlocked_provinces_province_id_fkey TO unlocked_destinations_destination_id_fkey;
ALTER TABLE public.unlocked_destinations RENAME CONSTRAINT unlocked_provinces_user_id_fkey TO unlocked_destinations_user_id_fkey;
ALTER TABLE public.unlocked_destinations RENAME CONSTRAINT unlocked_provinces_user_id_province_id_key TO unlocked_destinations_user_destination_key;
ALTER TABLE public.unlocked_destinations RENAME CONSTRAINT unlocked_provinces_completion_percent_check TO unlocked_destinations_completion_check;

ALTER TABLE public.unlocked_destination_items RENAME CONSTRAINT unlocked_province_items_pkey TO unlocked_destination_items_pkey;
ALTER TABLE public.unlocked_destination_items RENAME CONSTRAINT unlocked_province_items_province_item_id_fkey TO unlocked_destination_items_item_id_fkey;
ALTER TABLE public.unlocked_destination_items RENAME CONSTRAINT unlocked_province_items_user_id_fkey TO unlocked_destination_items_user_id_fkey;
ALTER TABLE public.unlocked_destination_items RENAME CONSTRAINT unlocked_province_items_user_id_province_item_id_key TO unlocked_destination_items_user_item_key;
ALTER TABLE public.unlocked_destination_items RENAME CONSTRAINT unlocked_province_items_check TO unlocked_destination_items_equipped_check;

ALTER TABLE public.foods RENAME CONSTRAINT foods_province_id_fkey TO foods_destination_id_fkey;
ALTER TABLE public.foods RENAME CONSTRAINT foods_province_id_name_key TO foods_destination_name_key;
ALTER TABLE public.landmarks RENAME CONSTRAINT landmarks_province_id_fkey TO landmarks_destination_id_fkey;
ALTER TABLE public.landmarks RENAME CONSTRAINT landmarks_province_id_name_key TO landmarks_destination_name_key;
ALTER TABLE public.checkpoint_rewards RENAME CONSTRAINT checkpoint_rewards_province_item_id_fkey TO checkpoint_rewards_destination_item_id_fkey;
ALTER TABLE public.travel_events RENAME CONSTRAINT travel_events_province_id_fkey TO travel_events_destination_id_fkey;
ALTER TABLE public.travel_progress RENAME CONSTRAINT travel_progress_current_province_id_fkey TO travel_progress_current_destination_id_fkey;

ALTER TRIGGER travel_checkpoint_province ON public.travel_progress
  RENAME TO travel_checkpoint_destination;

CREATE OR REPLACE FUNCTION muse_private.validate_relations() RETURNS trigger
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
  IF NEW.current_checkpoint_id IS NOT NULL AND NOT EXISTS(
   SELECT 1 FROM public.destination_checkpoints
   WHERE id=NEW.current_checkpoint_id AND destination_id=NEW.current_destination_id
  ) THEN
   RAISE EXCEPTION 'Checkpoint must belong to current destination' USING ERRCODE='23514';
  END IF;
 ELSIF TG_TABLE_NAME='journals' THEN
  IF NEW.journal_type IS DISTINCT FROM OLD.journal_type OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN
   RAISE EXCEPTION 'Journal type and owner are immutable' USING ERRCODE='23514';
  END IF;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION muse_private.advance_journey(u uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.travel_progress; cp public.destination_checkpoints; uc public.user_checkpoint_progress;
 rw public.checkpoint_rewards; next_id bigint; bonus integer; available bigint; pct integer;
BEGIN
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u FOR UPDATE;
 IF NOT FOUND OR p.current_checkpoint_id IS NULL OR p.journey_status<>'in_progress' THEN RETURN; END IF;
 LOOP
  SELECT * INTO cp FROM public.destination_checkpoints WHERE id=p.current_checkpoint_id;
  IF NOT FOUND OR NOT cp.is_active THEN RAISE EXCEPTION 'Active checkpoint unavailable'; END IF;
  INSERT INTO public.user_checkpoint_progress(user_id,checkpoint_id,status,started_at)
  VALUES(u,cp.id,'in_progress',now()) ON CONFLICT(user_id,checkpoint_id) DO NOTHING;
  SELECT * INTO uc FROM public.user_checkpoint_progress WHERE user_id=u AND checkpoint_id=cp.id FOR UPDATE;
  IF uc.status='completed' THEN RAISE EXCEPTION 'Journey pointer is inconsistent'; END IF;
  available:=greatest(0,p.current_energy::bigint-p.journey_energy_used);
  UPDATE public.user_checkpoint_progress SET earned_energy=least(available,cp.required_energy)::integer WHERE id=uc.id;
  IF available<cp.required_energy THEN RETURN; END IF;
  UPDATE public.user_checkpoint_progress SET status='completed',completed_at=now() WHERE id=uc.id;
  p.journey_energy_used:=p.journey_energy_used+cp.required_energy;
  INSERT INTO public.travel_events(user_id,destination_id,checkpoint_id,event_type,source_id)
  VALUES(u,cp.destination_id,cp.id,'checkpoint_completed',uc.id);
  bonus:=0;
  FOR rw IN SELECT * FROM public.checkpoint_rewards WHERE checkpoint_id=cp.id ORDER BY order_index,id LOOP
   CASE rw.reward_type
    WHEN 'landmark' THEN
     INSERT INTO public.unlocked_landmarks(user_id,landmark_id,unlock_source) VALUES(u,rw.landmark_id,'checkpoint:'||cp.id) ON CONFLICT(user_id,landmark_id) DO NOTHING;
    WHEN 'food' THEN
     INSERT INTO public.unlocked_foods(user_id,food_id,unlock_source) VALUES(u,rw.food_id,'checkpoint:'||cp.id) ON CONFLICT(user_id,food_id) DO NOTHING;
    WHEN 'destination_item' THEN
     INSERT INTO public.unlocked_destination_items(user_id,destination_item_id,unlock_source) VALUES(u,rw.destination_item_id,'checkpoint:'||cp.id) ON CONFLICT(user_id,destination_item_id) DO NOTHING;
    WHEN 'energy' THEN bonus:=bonus+rw.energy_amount*rw.quantity;
   END CASE;
   INSERT INTO public.travel_events(user_id,destination_id,checkpoint_id,event_type,source_id,metadata)
   VALUES(u,cp.destination_id,cp.id,'reward_unlocked',uc.id,jsonb_build_object('reward_id',rw.id,'type',rw.reward_type));
  END LOOP;
  IF bonus>0 THEN
   INSERT INTO public.energy_transactions(user_id,source_type,source_id,amount,balance_after,description)
   VALUES(u,'checkpoint_reward',uc.id,bonus,p.current_energy+bonus,'Checkpoint reward');
   p.current_energy:=p.current_energy+bonus; p.lifetime_energy:=p.lifetime_energy+bonus;
  END IF;
  SELECT id INTO next_id FROM public.destination_checkpoints
   WHERE destination_id=cp.destination_id AND is_active AND (order_index,id)>(cp.order_index,cp.id)
   ORDER BY order_index,id LIMIT 1;
  SELECT floor(100.0*count(*) FILTER(WHERE up.status='completed')/greatest(count(*),1))::integer INTO pct
  FROM public.destination_checkpoints c LEFT JOIN public.user_checkpoint_progress up ON up.checkpoint_id=c.id AND up.user_id=u
  WHERE c.destination_id=cp.destination_id AND c.is_active;
  UPDATE public.unlocked_destinations SET completion_percent=pct,completed_at=CASE WHEN next_id IS NULL THEN now() ELSE NULL END WHERE user_id=u AND destination_id=cp.destination_id;
  UPDATE public.travel_progress SET current_checkpoint_id=next_id,current_energy=p.current_energy,
   lifetime_energy=p.lifetime_energy,journey_energy_used=p.journey_energy_used,last_progress_at=now(),
   journey_status=CASE WHEN next_id IS NULL THEN 'paused'::public.journey_status ELSE 'in_progress'::public.journey_status END
  WHERE user_id=u RETURNING * INTO p;
  IF next_id IS NULL THEN
   INSERT INTO public.travel_events(user_id,destination_id,event_type) VALUES(u,cp.destination_id,'destination_completed');
   IF NOT EXISTS(SELECT 1 FROM public.destinations d WHERE d.is_active AND NOT EXISTS(SELECT 1 FROM public.unlocked_destinations ud WHERE ud.user_id=u AND ud.destination_id=d.id AND ud.completed_at IS NOT NULL)) THEN
    UPDATE public.travel_progress SET journey_status='completed' WHERE user_id=u;
   END IF;
   RETURN;
  END IF;
  INSERT INTO public.user_checkpoint_progress(user_id,checkpoint_id,status,started_at) VALUES(u,next_id,'in_progress',now()) ON CONFLICT(user_id,checkpoint_id) DO NOTHING;
  INSERT INTO public.travel_events(user_id,destination_id,checkpoint_id,event_type) VALUES(u,cp.destination_id,next_id,'checkpoint_started');
 END LOOP;
END $$;

CREATE OR REPLACE FUNCTION public.start_journey() RETURNS public.travel_progress
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); p public.travel_progress; destination bigint; checkpoint bigint;
BEGIN
 INSERT INTO public.travel_progress(user_id) VALUES(u) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u FOR UPDATE;
 IF p.current_checkpoint_id IS NOT NULL THEN RETURN p; END IF;
 SELECT d.id INTO destination FROM public.destinations d WHERE d.is_active AND NOT EXISTS(
  SELECT 1 FROM public.unlocked_destinations ud WHERE ud.user_id=u AND ud.destination_id=d.id AND ud.completed_at IS NOT NULL
 ) ORDER BY d.order_index,d.id LIMIT 1;
 IF destination IS NULL THEN RETURN p; END IF;
 SELECT id INTO checkpoint FROM public.destination_checkpoints WHERE destination_id=destination AND is_active ORDER BY order_index,id LIMIT 1;
 IF checkpoint IS NULL THEN RAISE EXCEPTION 'Destination has no active checkpoints'; END IF;
 INSERT INTO public.unlocked_destinations(user_id,destination_id) VALUES(u,destination) ON CONFLICT(user_id,destination_id) DO NOTHING;
 INSERT INTO public.user_checkpoint_progress(user_id,checkpoint_id,status,started_at) VALUES(u,checkpoint,'in_progress',now()) ON CONFLICT(user_id,checkpoint_id) DO NOTHING;
 UPDATE public.travel_progress SET current_destination_id=destination,current_checkpoint_id=checkpoint,journey_status='in_progress',started_at=coalesce(started_at,now()),last_progress_at=now() WHERE user_id=u;
 INSERT INTO public.travel_events(user_id,destination_id,checkpoint_id,event_type) VALUES(u,destination,checkpoint,'destination_unlocked');
 INSERT INTO public.travel_events(user_id,destination_id,checkpoint_id,event_type) VALUES(u,destination,checkpoint,'checkpoint_started');
 IF p.started_at IS NULL THEN INSERT INTO public.travel_events(user_id,destination_id,event_type) VALUES(u,destination,'journey_started'); END IF;
 PERFORM muse_private.advance_journey(u);
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u;
 RETURN p;
END $$;

CREATE OR REPLACE FUNCTION public.complete_mission(p_mission_id uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); m public.user_missions; p public.travel_progress; reward integer;
BEGIN
 SELECT * INTO m FROM public.user_missions WHERE id=p_mission_id AND user_id=u AND deleted_at IS NULL FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Mission unavailable' USING ERRCODE='42501'; END IF;
 IF m.reward_claimed_at IS NOT NULL THEN RETURN jsonb_build_object('mission_id',m.id,'already_completed',true,'reward',m.energy_reward); END IF;
 IF m.status NOT IN ('pending','in_progress') OR (m.due_at IS NOT NULL AND m.due_at<=now()) THEN RAISE EXCEPTION 'Mission cannot be completed'; END IF;
 reward:=CASE WHEN m.source_type='user_created' THEN 5 ELSE m.energy_reward END;
 INSERT INTO public.travel_progress(user_id) VALUES(u) ON CONFLICT(user_id) DO NOTHING;
 UPDATE public.travel_progress SET current_energy=current_energy+reward,lifetime_energy=lifetime_energy+reward WHERE user_id=u RETURNING * INTO p;
 IF reward>0 THEN
  INSERT INTO public.energy_transactions(user_id,source_type,source_id,amount,balance_after,description) VALUES(u,'mission',m.id,reward,p.current_energy,'Mission completed');
 END IF;
 UPDATE public.user_missions SET status='completed',completed_at=now(),reward_claimed_at=now(),energy_reward=reward WHERE id=m.id;
 INSERT INTO public.travel_events(user_id,destination_id,checkpoint_id,event_type,energy_amount,source_id) VALUES(u,p.current_destination_id,p.current_checkpoint_id,'energy_earned',reward,m.id);
 PERFORM muse_private.advance_journey(u);
 RETURN jsonb_build_object('mission_id',m.id,'already_completed',false,'reward',reward);
END $$;

CREATE OR REPLACE FUNCTION public.set_item_equipped(p_item_id bigint,p_equipped boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); category public.destination_item_type;
BEGIN
 SELECT i.item_type INTO category FROM public.destination_items i JOIN public.unlocked_destination_items ui ON ui.destination_item_id=i.id WHERE ui.user_id=u AND i.id=p_item_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Item not owned' USING ERRCODE='42501'; END IF;
 IF p_equipped THEN
  UPDATE public.unlocked_destination_items ui SET is_equipped=false,equipped_at=NULL FROM public.destination_items i WHERE ui.user_id=u AND ui.destination_item_id=i.id AND i.item_type=category;
 END IF;
 UPDATE public.unlocked_destination_items SET is_equipped=p_equipped,equipped_at=CASE WHEN p_equipped THEN now() ELSE NULL END,is_viewed=true WHERE user_id=u AND destination_item_id=p_item_id;
END $$;

NOTIFY pgrst, 'reload schema';
