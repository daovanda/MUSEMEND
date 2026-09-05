create extension if not exists pg_net with schema extensions;

do $$
begin
  if not exists (
    select 1
    from vault.secrets
    where name = 'musemend_cleanup_secret'
  ) then
    raise exception 'Vault secret musemend_cleanup_secret is required';
  end if;
end
$$;

select cron.schedule(
  'musemend-cleanup-worker',
  '*/5 * * * *',
  $cron$
    select net.http_post(
      url := 'https://jpoktrdyehalxkhdhkzu.supabase.co/functions/v1/musemend-cleanup',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-cleanup-secret',
        (
          select decrypted_secret
          from vault.decrypted_secrets
          where name = 'musemend_cleanup_secret'
        )
      ),
      body := '{}'::jsonb,
      timeout_milliseconds := 10000
    ) as request_id;
  $cron$
);
