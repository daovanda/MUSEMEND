import { createClient } from "npm:@supabase/supabase-js@2";

const url = Deno.env.get("SUPABASE_URL")!;
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const expectedSecret = Deno.env.get("MUSEMEND_CLEANUP_SECRET");

Deno.serve(async (request) => {
  if (!expectedSecret || request.headers.get("x-cleanup-secret") !== expectedSecret) {
    return new Response("Unauthorized", { status: 401 });
  }
  const db = createClient(url, serviceKey, { auth: { persistSession: false } });
  const { data: jobs, error: claimError } = await db.rpc("claim_storage_cleanup", { p_limit: 50 });
  if (claimError) return Response.json({ error: claimError.message }, { status: 500 });

  const results: Array<Record<string, unknown>> = [];
  for (const job of jobs ?? []) {
    const { error } = await db.storage.from(job.bucket_id).remove([job.object_path]);
    const message = error?.message ?? null;
    const { error: finishError } = await db.rpc("finish_storage_cleanup", {
      p_id: job.id, p_lease: job.lease_token, p_error: message,
    });
    results.push({ id: job.id, removed: !error, error: message ?? finishError?.message ?? null });
  }

  const { data: ready, error: readyError } = await db.rpc("list_ready_account_deletions");
  if (readyError) return Response.json({ processed: results, error: readyError.message }, { status: 500 });
  for (const row of ready ?? []) {
    const { error } = await db.auth.admin.deleteUser(row.user_id);
    results.push({ userId: row.user_id, accountDeleted: !error, error: error?.message ?? null });
  }
  return Response.json({ processed: results });
});

