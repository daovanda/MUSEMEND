class JourneyCheckpoint {
  const JourneyCheckpoint({
    required this.id,
    required this.number,
    required this.title,
    required this.description,
    required this.requiredEnergy,
    required this.earnedEnergy,
    required this.status,
    this.assetPath,
  });

  final int id;
  final int number;
  final String title;
  final String? description;
  final int requiredEnergy;
  final int earnedEnergy;
  final String status;

  /// Server-owned artwork for this checkpoint. It remains null until the
  /// corresponding catalog object has an approved export.
  final String? assetPath;

  double get progress =>
      requiredEnergy == 0
          ? 0
          : (earnedEnergy / requiredEnergy).clamp(0, 1).toDouble();

  bool get isCompleted => status == 'completed';
  bool get isCurrent => status == 'in_progress';
}
