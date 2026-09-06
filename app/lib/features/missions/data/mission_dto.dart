import 'package:musemend/features/missions/domain/mission_status.dart';
import 'package:musemend/features/missions/domain/user_mission.dart';

class MissionDto {
  const MissionDto({
    required this.id,
    required this.templateId,
    required this.title,
    required this.description,
    required this.energyReward,
    required this.status,
    required this.sourceType,
    required this.dueAt,
  });

  factory MissionDto.fromMap(Map<String, dynamic> row) {
    return MissionDto(
      id: row['id'] as String,
      templateId: (row['template_id'] as num?)?.toInt(),
      title: row['title_snapshot'] as String,
      description: row['description_snapshot'] as String?,
      energyReward: (row['energy_reward'] as num).toInt(),
      status: row['status'] as String,
      sourceType: row['source_type'] as String,
      dueAt:
          row['due_at'] == null
              ? null
              : DateTime.parse(row['due_at'] as String),
    );
  }

  final String id;
  final int? templateId;
  final String title;
  final String? description;
  final int energyReward;
  final String status;
  final String sourceType;
  final DateTime? dueAt;

  UserMission toDomain() {
    return UserMission(
      id: id,
      templateId: templateId,
      title: title,
      description: description,
      energyReward: energyReward,
      status: MissionStatus.fromDatabase(status),
      sourceType: sourceType,
      dueAt: dueAt,
    );
  }
}
