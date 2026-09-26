-- Retarget only existing system suggestions whose activity is appropriate for
-- the selected mood. Leave starter and other neutral activities available
-- before the day's check-in. Titles/translations and rewards stay unchanged.
UPDATE public.mission_templates AS template
SET target_mood = mapping.target_mood::public.target_mood_type
FROM (VALUES
  ('content-mission-03', 'awful'),
  ('content-mission-09', 'awful'),
  ('content-mission-10', 'sad'),
  ('content-mission-13', 'sad'),
  ('content-mission-05', 'okay'),
  ('content-mission-08', 'okay'),
  ('content-mission-12', 'good'),
  ('content-mission-18', 'good'),
  ('content-mission-07', 'great'),
  ('content-mission-14', 'great')
) AS mapping(code, target_mood)
WHERE template.code = mapping.code
  AND template.is_system = true;
