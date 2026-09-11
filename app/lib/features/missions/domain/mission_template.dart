import 'package:musemend/features/missions/domain/mission_type.dart';

class MissionTemplate {
  const MissionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMood,
    required this.energyReward,
    required this.estimatedMinutes,
    required this.missionType,
  });

  final int id;
  final String title;
  final String? description;
  final String targetMood;
  final int energyReward;
  final int? estimatedMinutes;
  final MissionType missionType;

  bool get requiresMood => targetMood != 'all';
}
