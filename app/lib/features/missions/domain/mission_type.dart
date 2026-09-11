enum MissionType {
  daily('daily', 'Ngày'),
  weekly('weekly', 'Tuần'),
  monthly('monthly', 'Tháng'),
  yearly('yearly', 'Năm'),
  custom('custom', 'Tùy chỉnh');

  const MissionType(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

  static MissionType fromDatabase(String value) {
    if (value == 'one_time') return MissionType.custom;
    return MissionType.values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => MissionType.custom,
    );
  }
}
