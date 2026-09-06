-- All reward and journey mutations are serialized by require_user()'s profile lock.
CREATE FUNCTION muse_private.advance_journey(u uuid) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p public.travel_progress; cp public.province_checkpoints; uc public.user_checkpoint_progress;
 rw public.checkpoint_rewards; next_id bigint; bonus integer; available bigint; pct integer;
BEGIN
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u FOR UPDATE;
 IF NOT FOUND OR p.current_checkpoint_id IS NULL OR p.journey_status<>'in_progress' THEN RETURN; END IF;
 LOOP
  SELECT * INTO cp FROM public.province_checkpoints WHERE id=p.current_checkpoint_id;
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
  INSERT INTO public.travel_events(user_id,province_id,checkpoint_id,event_type,source_id)
  VALUES(u,cp.province_id,cp.id,'checkpoint_completed',uc.id);
  bonus:=0;
  FOR rw IN SELECT * FROM public.checkpoint_rewards WHERE checkpoint_id=cp.id ORDER BY order_index,id LOOP
   CASE rw.reward_type
    WHEN 'landmark' THEN
     INSERT INTO public.unlocked_landmarks(user_id,landmark_id,unlock_source) VALUES(u,rw.landmark_id,'checkpoint:'||cp.id) ON CONFLICT(user_id,landmark_id) DO NOTHING;
    WHEN 'food' THEN
     INSERT INTO public.unlocked_foods(user_id,food_id,unlock_source) VALUES(u,rw.food_id,'checkpoint:'||cp.id) ON CONFLICT(user_id,food_id) DO NOTHING;
    WHEN 'province_item' THEN
     INSERT INTO public.unlocked_province_items(user_id,province_item_id,unlock_source) VALUES(u,rw.province_item_id,'checkpoint:'||cp.id) ON CONFLICT(user_id,province_item_id) DO NOTHING;
    WHEN 'energy' THEN bonus:=bonus+rw.energy_amount*rw.quantity;
   END CASE;
   INSERT INTO public.travel_events(user_id,province_id,checkpoint_id,event_type,source_id,metadata)
   VALUES(u,cp.province_id,cp.id,'reward_unlocked',uc.id,jsonb_build_object('reward_id',rw.id,'type',rw.reward_type));
  END LOOP;
  IF bonus>0 THEN
   INSERT INTO public.energy_transactions(user_id,source_type,source_id,amount,balance_after,description)
   VALUES(u,'checkpoint_reward',uc.id,bonus,p.current_energy+bonus,'Checkpoint reward');
   p.current_energy:=p.current_energy+bonus; p.lifetime_energy:=p.lifetime_energy+bonus;
  END IF;
  SELECT id INTO next_id FROM public.province_checkpoints
   WHERE province_id=cp.province_id AND is_active AND (order_index,id)>(cp.order_index,cp.id)
   ORDER BY order_index,id LIMIT 1;
  SELECT floor(100.0*count(*) FILTER(WHERE up.status='completed')/greatest(count(*),1))::integer INTO pct
  FROM public.province_checkpoints c LEFT JOIN public.user_checkpoint_progress up ON up.checkpoint_id=c.id AND up.user_id=u
  WHERE c.province_id=cp.province_id AND c.is_active;
  UPDATE public.unlocked_provinces SET completion_percent=pct,completed_at=CASE WHEN next_id IS NULL THEN now() ELSE NULL END WHERE user_id=u AND province_id=cp.province_id;
  UPDATE public.travel_progress SET current_checkpoint_id=next_id,current_energy=p.current_energy,
   lifetime_energy=p.lifetime_energy,journey_energy_used=p.journey_energy_used,last_progress_at=now(),
   journey_status=CASE WHEN next_id IS NULL THEN 'paused'::public.journey_status ELSE 'in_progress'::public.journey_status END
  WHERE user_id=u RETURNING * INTO p;
  IF next_id IS NULL THEN
   INSERT INTO public.travel_events(user_id,province_id,event_type) VALUES(u,cp.province_id,'province_completed');
   IF NOT EXISTS(SELECT 1 FROM public.provinces v WHERE v.is_active AND NOT EXISTS(SELECT 1 FROM public.unlocked_provinces uv WHERE uv.user_id=u AND uv.province_id=v.id AND uv.completed_at IS NOT NULL)) THEN
    UPDATE public.travel_progress SET journey_status='completed' WHERE user_id=u;
   END IF;
   RETURN;
  END IF;
  INSERT INTO public.user_checkpoint_progress(user_id,checkpoint_id,status,started_at) VALUES(u,next_id,'in_progress',now()) ON CONFLICT(user_id,checkpoint_id) DO NOTHING;
  INSERT INTO public.travel_events(user_id,province_id,checkpoint_id,event_type) VALUES(u,cp.province_id,next_id,'checkpoint_started');
 END LOOP;
END $$;

CREATE FUNCTION public.start_journey() RETURNS public.travel_progress
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); p public.travel_progress; province bigint; checkpoint bigint;
BEGIN
 INSERT INTO public.travel_progress(user_id) VALUES(u) ON CONFLICT(user_id) DO NOTHING;
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u FOR UPDATE;
 IF p.current_checkpoint_id IS NOT NULL THEN RETURN p; END IF;
 SELECT v.id INTO province FROM public.provinces v WHERE v.is_active AND NOT EXISTS(
  SELECT 1 FROM public.unlocked_provinces uv WHERE uv.user_id=u AND uv.province_id=v.id AND uv.completed_at IS NOT NULL
 ) ORDER BY v.order_index,v.id LIMIT 1;
 IF province IS NULL THEN RETURN p; END IF;
 SELECT id INTO checkpoint FROM public.province_checkpoints WHERE province_id=province AND is_active ORDER BY order_index,id LIMIT 1;
 IF checkpoint IS NULL THEN RAISE EXCEPTION 'Province has no active checkpoints'; END IF;
 INSERT INTO public.unlocked_provinces(user_id,province_id) VALUES(u,province) ON CONFLICT(user_id,province_id) DO NOTHING;
 INSERT INTO public.user_checkpoint_progress(user_id,checkpoint_id,status,started_at) VALUES(u,checkpoint,'in_progress',now()) ON CONFLICT(user_id,checkpoint_id) DO NOTHING;
 UPDATE public.travel_progress SET current_province_id=province,current_checkpoint_id=checkpoint,journey_status='in_progress',started_at=coalesce(started_at,now()),last_progress_at=now() WHERE user_id=u;
 INSERT INTO public.travel_events(user_id,province_id,checkpoint_id,event_type) VALUES(u,province,checkpoint,'province_unlocked');
 INSERT INTO public.travel_events(user_id,province_id,checkpoint_id,event_type) VALUES(u,province,checkpoint,'checkpoint_started');
 IF p.started_at IS NULL THEN INSERT INTO public.travel_events(user_id,province_id,event_type) VALUES(u,province,'journey_started'); END IF;
 PERFORM muse_private.advance_journey(u);
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u;
 RETURN p;
END $$;

CREATE FUNCTION public.advance_journey() RETURNS public.travel_progress
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); p public.travel_progress;
BEGIN
 PERFORM muse_private.advance_journey(u);
 SELECT * INTO p FROM public.travel_progress WHERE user_id=u;
 RETURN p;
END $$;

CREATE FUNCTION public.complete_mission(p_mission_id uuid) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); m public.user_missions; p public.travel_progress; reward integer;
BEGIN
 SELECT * INTO m FROM public.user_missions WHERE id=p_mission_id AND user_id=u AND deleted_at IS NULL FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Mission unavailable' USING ERRCODE='42501'; END IF;
 IF m.reward_claimed_at IS NOT NULL THEN RETURN jsonb_build_object('mission_id',m.id,'already_completed',true,'reward',m.energy_reward); END IF;
 IF m.status NOT IN ('pending','in_progress') OR (m.due_at IS NOT NULL AND m.due_at<=now()) THEN RAISE EXCEPTION 'Mission cannot be completed'; END IF;
 -- Snapshot is server-created, never writable by clients.
 reward:=CASE WHEN m.source_type='user_created' THEN 5 ELSE m.energy_reward END;
 INSERT INTO public.travel_progress(user_id) VALUES(u) ON CONFLICT(user_id) DO NOTHING;
 UPDATE public.travel_progress SET current_energy=current_energy+reward,lifetime_energy=lifetime_energy+reward WHERE user_id=u RETURNING * INTO p;
 IF reward>0 THEN
  INSERT INTO public.energy_transactions(user_id,source_type,source_id,amount,balance_after,description) VALUES(u,'mission',m.id,reward,p.current_energy,'Mission completed');
 END IF;
 UPDATE public.user_missions SET status='completed',completed_at=now(),reward_claimed_at=now(),energy_reward=reward WHERE id=m.id;
 INSERT INTO public.travel_events(user_id,province_id,checkpoint_id,event_type,energy_amount,source_id) VALUES(u,p.current_province_id,p.current_checkpoint_id,'energy_earned',reward,m.id);
 PERFORM muse_private.advance_journey(u);
 RETURN jsonb_build_object('mission_id',m.id,'already_completed',false,'reward',reward);
END $$;

CREATE FUNCTION public.set_item_equipped(p_item_id bigint,p_equipped boolean) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE u uuid:=muse_private.require_user(); category public.province_item_type;
BEGIN
 SELECT i.item_type INTO category FROM public.province_items i JOIN public.unlocked_province_items ui ON ui.province_item_id=i.id WHERE ui.user_id=u AND i.id=p_item_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Item not owned' USING ERRCODE='42501'; END IF;
 IF p_equipped THEN
  UPDATE public.unlocked_province_items ui SET is_equipped=false,equipped_at=NULL FROM public.province_items i WHERE ui.user_id=u AND ui.province_item_id=i.id AND i.item_type=category;
 END IF;
 UPDATE public.unlocked_province_items SET is_equipped=p_equipped,equipped_at=CASE WHEN p_equipped THEN now() ELSE NULL END,is_viewed=true WHERE user_id=u AND province_item_id=p_item_id;
END $$;

