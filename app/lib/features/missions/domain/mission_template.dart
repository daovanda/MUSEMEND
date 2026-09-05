class MissionTemplate {
  const MissionTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.targetMood,
    required this.energyReward,
    required this.estimatedMinutes,
  });

  final int id;
  final String title;
  final String? description;
  final String targetMood;
  final int energyReward;
  final int? estimatedMinutes;

  bool get requiresMood => targetMood != 'all';
}
