import { PGlite } from '@electric-sql/pglite';
import { readFile, readdir } from 'node:fs/promises';
const db = new PGlite();
await db.exec(`
CREATE ROLE anon; CREATE ROLE authenticated; CREATE ROLE service_role BYPASSRLS;
CREATE SCHEMA auth; CREATE SCHEMA storage;
GRANT USAGE ON SCHEMA auth,storage TO anon,authenticated,service_role;
CREATE TABLE auth.users(id uuid PRIMARY KEY,email text,raw_user_meta_data jsonb DEFAULT '{}',raw_app_meta_data jsonb DEFAULT '{}',is_anonymous boolean DEFAULT false);
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$ SELECT nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
CREATE TABLE storage.buckets(id text PRIMARY KEY,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
CREATE TABLE storage.objects(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),bucket_id text REFERENCES storage.buckets(id),name text,owner_id text,UNIQUE(bucket_id,name));
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
GRANT SELECT,INSERT,UPDATE,DELETE ON storage.objects TO authenticated,service_role;
`);
for (const name of (await readdir('supabase/migrations')).filter(x=>x.endsWith('.sql')&&!x.includes('schedule')).sort()) {
  console.log('Applying',name);
  await db.exec(await readFile('supabase/migrations/'+name,'utf8'));
}
console.log('Running integration tests (transaction rollback)');
try {
  await db.exec(await readFile('supabase/tests/mvp_integration.sql','utf8'));
} catch (error) {
  console.error(error.message, error.detail ?? '', error.position ?? '');
  process.exitCode = 1;
  await db.close();
  process.exit();
}
console.log('PASS: migrations and integration tests');
await db.close();
