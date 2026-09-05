enum MissionStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed'),
  skipped('skipped'),
  expired('expired'),
  cancelled('cancelled');

  const MissionStatus(this.databaseValue);

  final String databaseValue;

  static MissionStatus fromDatabase(String value) {
    return MissionStatus.values.firstWhere(
      (status) => status.databaseValue == value,
      orElse: () => throw FormatException('Unsupported mission status: $value'),
    );
  }
}
