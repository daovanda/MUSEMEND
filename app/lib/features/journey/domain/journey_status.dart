enum JourneyStatus {
  notStarted,
  inProgress,
  paused,
  completed;

  factory JourneyStatus.fromDatabase(String value) {
    return switch (value) {
      'not_started' => JourneyStatus.notStarted,
      'in_progress' => JourneyStatus.inProgress,
      'paused' => JourneyStatus.paused,
      'completed' => JourneyStatus.completed,
      _ => throw FormatException('Unknown journey status: $value'),
    };
  }
}
