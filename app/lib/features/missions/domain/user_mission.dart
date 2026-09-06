import 'package:musemend/features/missions/domain/mission_status.dart';

class UserMission {
  const UserMission({
    required this.id,
    required this.templateId,
    required this.title,
    required this.description,
    required this.energyReward,
    required this.status,
    required this.sourceType,
    required this.dueAt,
  });

  final String id;
  final int? templateId;
  final String title;
  final String? description;
  final int energyReward;
  final MissionStatus status;
  final String sourceType;
  final DateTime? dueAt;

  bool get isCustom => sourceType == 'user_created';
}
