import 'package:musemend/features/missions/domain/mission_template.dart';

class MissionTemplateDto {
  const MissionTemplateDto({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMood,
    required this.energyReward,
    required this.estimatedMinutes,
  });

  factory MissionTemplateDto.fromMap(Map<String, dynamic> row) {
    return MissionTemplateDto(
      id: (row['id'] as num).toInt(),
      title: row['title'] as String,
      description: row['description'] as String?,
      targetMood: row['target_mood'] as String,
      energyReward: (row['default_energy_reward'] as num).toInt(),
      estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt(),
    );
  }

  final int id;
  final String title;
  final String? description;
  final String targetMood;
  final int energyReward;
  final int? estimatedMinutes;

  MissionTemplate toDomain() {
    return MissionTemplate(
      id: id,
      title: title,
      description: description,
      targetMood: targetMood,
      energyReward: energyReward,
      estimatedMinutes: estimatedMinutes,
    );
  }
}
