enum MissionType {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly'),
  custom('custom');

  const MissionType(this.databaseValue);

  final String databaseValue;

  static MissionType fromDatabase(String value) {
    if (value == 'one_time') return MissionType.custom;
    return MissionType.values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => MissionType.custom,
    );
  }
}
