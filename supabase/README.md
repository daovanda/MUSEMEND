# MuseMend Supabase backend

The migration files in this directory are the source of truth for the MVP database.

## Applied MVP behavior

- One editable check-in per Vietnam calendar day: call `upsert_daily_checkin`.
- App-open streak: call `record_app_open` once on each authenticated launch/resume. It is idempotent for that day.
- Missions: call `create_mission`, then `complete_mission`. Never write reward/progress tables directly.
- Custom missions always award 5 energy; no daily limit is imposed.
- Journey: call `start_journey`. Mission completion advances checkpoints automatically; `advance_journey` may be retried safely.
- Journals: call `save_journal`; it atomically writes the common row and subtype. Future letters are readable/editable before delivery.
- Future-letter due notifications are rows in `notifications`; database housekeeping creates them every minute. The app should subscribe/query this table and schedule/display platform push/local notifications.
- Media bucket: `journal-media`, private. Object path must be `<user UUID>/<journal UUID>/<unique file name>`. Upload first, then call `attach_journal_media`.
- Journal media is retained for 30 days after soft deletion. Account deletion queues immediate Storage cleanup and disables the profile.

## Cleanup worker

The database queues physical Storage deletion, but deleting the actual object and
the Auth user must go through Supabase APIs. Edge Function
`supabase/functions/musemend-cleanup` is deployed in the current development
project and invoked by a trusted scheduler with the matching
`x-cleanup-secret` header.

Each environment must provision its own `MUSEMEND_CLEANUP_SECRET` and matching
Vault secret. Do not embed the service-role key or cleanup secret in the mobile
app. Supabase automatically supplies its URL and service-role key to deployed
Edge Functions.

## Validation

Run:

```powershell
npm ci --prefix tools/db-validation
node tools/db-validation/validate.mjs
```

The runner creates a temporary embedded PostgreSQL database, applies all replayable
migrations except hosted cron schedules, and runs
`supabase/tests/mvp_integration.sql` inside a rolled-back transaction.

`supabase/baseline/schema_snapshot.json` is a metadata snapshot of the pre-change
schema. Migration `20260905042807_adopt_mvp_baseline.sql` bootstraps an empty
public schema, but is a no-op on the adopted remote MVP.

See [database documentation](../docs/db/README.md) and
[backend documentation](../docs/be/README.md) for contracts and operational notes.
