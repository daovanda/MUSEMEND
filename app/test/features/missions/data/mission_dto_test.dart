import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/missions/data/mission_dto.dart';
import 'package:musemend/features/missions/data/mission_template_dto.dart';
import 'package:musemend/features/missions/domain/mission_status.dart';

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
          'due_at': null,
        }).toDomain();

    expect(mission.energyReward, 5);
    expect(mission.status, MissionStatus.pending);
    expect(mission.isCustom, isTrue);
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
        }).toDomain();

    expect(template.requiresMood, isTrue);
    expect(template.estimatedMinutes, 2);
  });
}
