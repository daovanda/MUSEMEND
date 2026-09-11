import 'package:musemend/features/missions/domain/mission_status.dart';
import 'package:musemend/features/missions/domain/mission_type.dart';

class UserMission {
  const UserMission({
    required this.id,
    required this.templateId,
    required this.title,
    required this.description,
    required this.energyReward,
    required this.status,
    required this.sourceType,
    required this.missionType,
    required this.startAt,
    required this.dueAt,
  });

  final String id;
  final int? templateId;
  final String title;
  final String? description;
  final int energyReward;
  final MissionStatus status;
  final String sourceType;
  final MissionType missionType;
  final DateTime startAt;
  final DateTime? dueAt;

  bool get isCustom => sourceType == 'user_created';
}
