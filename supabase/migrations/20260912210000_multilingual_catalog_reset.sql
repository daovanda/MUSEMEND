-- Pre-launch development reset and multilingual catalog foundation.
--
-- This migration intentionally removes every existing MuseMend application
-- row and every Supabase Auth user. It preserves database structure, migration
-- history, the private journal bucket and queued Storage cleanup work.

create table public.supported_languages (
  code text primary key,
  english_name text not null,
  native_name text not null,
  fallback_code text,
  order_index smallint not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint supported_languages_code_check
    check (code ~ '^[a-z]{2}$'),
  constraint supported_languages_names_check
    check (
      char_length(btrim(english_name)) between 1 and 80
      and char_length(btrim(native_name)) between 1 and 80
    ),
  constraint supported_languages_order_check check (order_index > 0),
  constraint supported_languages_fallback_fkey
    foreign key (fallback_code)
    references public.supported_languages(code)
    on update cascade
    on delete restrict
);

insert into public.supported_languages (
  code,
  english_name,
  native_name,
  fallback_code,
  order_index
) values
  ('vi', 'Vietnamese', 'Tiếng Việt', 'en', 1),
  ('en', 'English', 'English', null, 2),
  ('ja', 'Japanese', '日本語', 'en', 3),
  ('fr', 'French', 'Français', 'en', 4),
  ('es', 'Spanish', 'Español', 'en', 5),
  ('it', 'Italian', 'Italiano', 'en', 6),
  ('de', 'German', 'Deutsch', 'en', 7),
  ('ko', 'Korean', '한국어', 'en', 8),
  ('pt', 'Portuguese', 'Português', 'en', 9),
  ('ms', 'Malay', 'Bahasa Melayu', 'en', 10),
  ('id', 'Indonesian', 'Bahasa Indonesia', 'en', 11),
  ('th', 'Thai', 'ไทย', 'en', 12);

create table public.destination_translations (
  destination_id bigint not null
    references public.destinations(id) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (destination_id, language_code),
  constraint destination_translations_name_check
    check (char_length(btrim(name)) between 1 and 160),
  constraint destination_translations_description_check
    check (description is null or char_length(btrim(description)) between 1 and 4000)
);

create table public.checkpoint_translations (
  checkpoint_id bigint not null
    references public.destination_checkpoints(id) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  title text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (checkpoint_id, language_code),
  constraint checkpoint_translations_title_check
    check (char_length(btrim(title)) between 1 and 200),
  constraint checkpoint_translations_description_check
    check (description is null or char_length(btrim(description)) between 1 and 4000)
);

create table public.landmark_translations (
  landmark_id bigint not null
    references public.landmarks(id) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  name text not null,
  description text,
  story_content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (landmark_id, language_code),
  constraint landmark_translations_name_check
    check (char_length(btrim(name)) between 1 and 200),
  constraint landmark_translations_description_check
    check (description is null or char_length(btrim(description)) between 1 and 4000),
  constraint landmark_translations_story_check
    check (story_content is null or char_length(btrim(story_content)) between 1 and 20000)
);

create table public.food_translations (
  food_id bigint not null
    references public.foods(id) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  name text not null,
  description text,
  story_content text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (food_id, language_code),
  constraint food_translations_name_check
    check (char_length(btrim(name)) between 1 and 200),
  constraint food_translations_description_check
    check (description is null or char_length(btrim(description)) between 1 and 4000),
  constraint food_translations_story_check
    check (story_content is null or char_length(btrim(story_content)) between 1 and 20000)
);

create table public.destination_item_translations (
  destination_item_id bigint not null
    references public.destination_items(id) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  name text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (destination_item_id, language_code),
  constraint destination_item_translations_name_check
    check (char_length(btrim(name)) between 1 and 200),
  constraint destination_item_translations_description_check
    check (description is null or char_length(btrim(description)) between 1 and 4000)
);

create table public.mission_template_translations (
  mission_template_id bigint not null
    references public.mission_templates(id) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  title text not null,
  description text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (mission_template_id, language_code),
  constraint mission_template_translations_title_check
    check (char_length(btrim(title)) between 1 and 200),
  constraint mission_template_translations_description_check
    check (description is null or char_length(btrim(description)) between 1 and 4000)
);

create table public.daily_quote_translations (
  quote_rotation_order smallint not null
    references public.daily_quotes(rotation_order) on delete cascade,
  language_code text not null
    references public.supported_languages(code) on update cascade on delete restrict,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (quote_rotation_order, language_code),
  constraint daily_quote_translations_content_check
    check (char_length(btrim(content)) between 1 and 240)
);

create index destination_translations_language_idx
  on public.destination_translations(language_code, destination_id);
create index checkpoint_translations_language_idx
  on public.checkpoint_translations(language_code, checkpoint_id);
create index landmark_translations_language_idx
  on public.landmark_translations(language_code, landmark_id);
create index food_translations_language_idx
  on public.food_translations(language_code, food_id);
create index destination_item_translations_language_idx
  on public.destination_item_translations(language_code, destination_item_id);
create index mission_template_translations_language_idx
  on public.mission_template_translations(language_code, mission_template_id);
create index daily_quote_translations_language_idx
  on public.daily_quote_translations(language_code, quote_rotation_order);

create trigger supported_languages_updated_at
before update on public.supported_languages
for each row execute function public.set_updated_at();
create trigger destination_translations_updated_at
before update on public.destination_translations
for each row execute function public.set_updated_at();
create trigger checkpoint_translations_updated_at
before update on public.checkpoint_translations
for each row execute function public.set_updated_at();
create trigger landmark_translations_updated_at
before update on public.landmark_translations
for each row execute function public.set_updated_at();
create trigger food_translations_updated_at
before update on public.food_translations
for each row execute function public.set_updated_at();
create trigger destination_item_translations_updated_at
before update on public.destination_item_translations
for each row execute function public.set_updated_at();
create trigger mission_template_translations_updated_at
before update on public.mission_template_translations
for each row execute function public.set_updated_at();
create trigger daily_quote_translations_updated_at
before update on public.daily_quote_translations
for each row execute function public.set_updated_at();

alter table public.supported_languages enable row level security;
alter table public.destination_translations enable row level security;
alter table public.checkpoint_translations enable row level security;
alter table public.landmark_translations enable row level security;
alter table public.food_translations enable row level security;
alter table public.destination_item_translations enable row level security;
alter table public.mission_template_translations enable row level security;
alter table public.daily_quote_translations enable row level security;

revoke all on table public.supported_languages from public, anon, authenticated;
revoke all on table public.destination_translations from public, anon, authenticated;
revoke all on table public.checkpoint_translations from public, anon, authenticated;
revoke all on table public.landmark_translations from public, anon, authenticated;
revoke all on table public.food_translations from public, anon, authenticated;
revoke all on table public.destination_item_translations from public, anon, authenticated;
revoke all on table public.mission_template_translations from public, anon, authenticated;
revoke all on table public.daily_quote_translations from public, anon, authenticated;

grant select on table public.supported_languages to authenticated;
grant select on table public.destination_translations to authenticated;
grant select on table public.checkpoint_translations to authenticated;
grant select on table public.landmark_translations to authenticated;
grant select on table public.food_translations to authenticated;
grant select on table public.destination_item_translations to authenticated;
grant select on table public.mission_template_translations to authenticated;
grant select on table public.daily_quote_translations to authenticated;

create policy catalog_language_read on public.supported_languages
for select to authenticated
using ((select muse_private.active_user()) and is_active);
create policy catalog_translation_read on public.destination_translations
for select to authenticated
using ((select muse_private.active_user()));
create policy catalog_translation_read on public.checkpoint_translations
for select to authenticated
using ((select muse_private.active_user()));
create policy catalog_translation_read on public.landmark_translations
for select to authenticated
using ((select muse_private.active_user()));
create policy catalog_translation_read on public.food_translations
for select to authenticated
using ((select muse_private.active_user()));
create policy catalog_translation_read on public.destination_item_translations
for select to authenticated
using ((select muse_private.active_user()));
create policy catalog_translation_read on public.mission_template_translations
for select to authenticated
using ((select muse_private.active_user()));
create policy catalog_translation_read on public.daily_quote_translations
for select to authenticated
using ((select muse_private.active_user()));

-- NULL means “follow the device locale”. Explicit choices must reference the
-- supported catalog. Unsupported device locales are resolved to English by the
-- Flutter client and localized RPCs.
alter table public.user_settings
  alter column language_code drop not null,
  alter column language_code drop default;

update public.user_settings settings
set language_code = null
where settings.language_code is not null
  and not exists (
    select 1
    from public.supported_languages language
    where language.code = settings.language_code
  );

alter table public.user_settings
  add constraint user_settings_language_code_fkey
  foreign key (language_code)
  references public.supported_languages(code)
  on update cascade
  on delete restrict;

create or replace function muse_private.resolve_language_code(
  p_language_code text
) returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select language.code
      from public.supported_languages language
      where language.code = lower(nullif(btrim(p_language_code), ''))
        and language.is_active
    ),
    'en'
  );
$$;

revoke all on function muse_private.resolve_language_code(text)
from public, anon, authenticated;

create or replace function public.get_daily_quote(p_language_code text)
returns table (
  rotation_order smallint,
  content text,
  topic text,
  quote_date date
)
language sql
security definer
set search_path = ''
as $$
  with context as (
    select
      muse_private.require_user() as user_id,
      (now() at time zone 'Asia/Ho_Chi_Minh')::date as quote_date,
      muse_private.resolve_language_code(p_language_code) as language_code
  )
  select
    quote.rotation_order,
    coalesce(requested.content, english.content, quote.content) as content,
    quote.topic,
    context.quote_date
  from context
  cross join lateral muse_private.daily_quote_for_date(context.quote_date) quote
  left join public.daily_quote_translations requested
    on requested.quote_rotation_order = quote.rotation_order
   and requested.language_code = context.language_code
  left join public.daily_quote_translations english
    on english.quote_rotation_order = quote.rotation_order
   and english.language_code = 'en';
$$;

revoke all on function public.get_daily_quote(text) from public, anon;
grant execute on function public.get_daily_quote(text) to authenticated;

create or replace function public.get_daily_quote()
returns table (
  rotation_order smallint,
  content text,
  topic text,
  quote_date date
)
language sql
security definer
set search_path = ''
as $$
  select localized.*
  from public.get_daily_quote(
    coalesce(
      (
        select settings.language_code
        from public.user_settings settings
        where settings.user_id = (select auth.uid())
      ),
      'en'
    )
  ) localized;
$$;

revoke all on function public.get_daily_quote() from public, anon;
grant execute on function public.get_daily_quote() to authenticated;

-- Queue physical journal objects for the existing cleanup worker before their
-- relational metadata is removed. Direct DELETEs against storage.objects are
-- intentionally avoided because they can orphan the underlying objects.
insert into public.storage_cleanup_jobs (
  user_id,
  journal_id,
  bucket_id,
  object_path,
  not_before
)
select
  journal.user_id,
  media.journal_id,
  'journal-media',
  media.storage_path,
  now()
from public.journal_media media
join public.journals journal on journal.id = media.journal_id
where media.storage_path is not null
on conflict (bucket_id, object_path) do update
set not_before = now(),
    status = 'pending',
    lease_until = null,
    lease_token = null,
    last_error = null;

truncate table
  public.account_deletion_requests,
  public.checkpoint_rewards,
  public.daily_checkins,
  public.daily_journals,
  public.daily_quotes,
  public.daily_visits,
  public.destination_checkpoints,
  public.destination_item_translations,
  public.destination_items,
  public.destination_translations,
  public.destinations,
  public.energy_transactions,
  public.food_translations,
  public.foods,
  public.future_letters,
  public.journal_media,
  public.journal_tag_assignments,
  public.journal_tags,
  public.journals,
  public.landmark_translations,
  public.landmarks,
  public.mission_template_translations,
  public.mission_templates,
  public.notifications,
  public.profiles,
  public.checkpoint_translations,
  public.travel_events,
  public.travel_progress,
  public.unlocked_destination_items,
  public.unlocked_destinations,
  public.unlocked_foods,
  public.unlocked_landmarks,
  public.user_checkpoint_progress,
  public.user_missions,
  public.user_settings,
  public.yearly_goals,
  public.yearly_highlights,
  public.yearly_journals,
  public.yearly_lessons
restart identity cascade;

delete from auth.users;

notify pgrst, 'reload schema';
