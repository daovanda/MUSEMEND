CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;
DO $$
DECLARE existing bigint;
BEGIN
 SELECT jobid INTO existing FROM cron.job WHERE jobname='musemend-housekeeping';
 IF existing IS NOT NULL THEN PERFORM cron.unschedule(existing); END IF;
 PERFORM cron.schedule('musemend-housekeeping','* * * * *','SELECT muse_private.housekeeping()');
END $$;

