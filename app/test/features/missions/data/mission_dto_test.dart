import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/missions/data/mission_dto.dart';
import 'package:musemend/features/missions/data/mission_template_dto.dart';
import 'package:musemend/features/missions/domain/mission_status.dart';
import 'package:musemend/features/missions/domain/mission_type.dart';

void main() {
  test('maps a user mission without trusting a client reward', () {
    final mission =
        MissionDto.fromMap({
          'id': '10000000-0000-4000-8000-000000000001',
          'template_id': null,
          'title_snapshot': 'Đi bộ 5 phút',
          'description_snapshot': null,
          'energy_reward': 5,
          'status': 'pending',
          'source_type': 'user_created',
          'mission_type': 'daily',
          'start_at': '2026-09-11T02:00:00Z',
          'due_at': '2026-09-11T03:00:00Z',
        }).toDomain();

    expect(mission.energyReward, 5);
    expect(mission.status, MissionStatus.pending);
    expect(mission.isCustom, isTrue);
    expect(mission.missionType, MissionType.daily);
  });

  test('maps a mood-aware template', () {
    final template =
        MissionTemplateDto.fromMap({
          'id': 10,
          'title': 'Hít thở chậm',
          'description': 'Ba nhịp thật nhẹ',
          'target_mood': 'sad',
          'default_energy_reward': 5,
          'estimated_minutes': 2,
          'mission_type': 'weekly',
          'mission_template_translations': [
            {
              'language_code': 'en',
              'title': 'Breathe slowly',
              'description': 'Three gentle breaths',
            },
          ],
        }, languageCode: 'en').toDomain();

    expect(template.requiresMood, isTrue);
    expect(template.estimatedMinutes, 2);
    expect(template.missionType, MissionType.weekly);
    expect(template.title, 'Breathe slowly');
  });

  test('falls back from unsupported template locale to English', () {
    final template =
        MissionTemplateDto.fromMap({
          'id': 11,
          'title': 'Uống một cốc nước',
          'description': null,
          'target_mood': 'all',
          'default_energy_reward': 5,
          'estimated_minutes': 1,
          'mission_type': 'daily',
          'mission_template_translations': [
            {
              'language_code': 'en',
              'title': 'Drink a glass of water',
              'description': null,
            },
          ],
        }, languageCode: 'ru').toDomain();

    expect(template.title, 'Drink a glass of water');
  });
}
