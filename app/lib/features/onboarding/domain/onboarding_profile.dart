enum PreferredAddress {
  cauMinh('cau_minh'),
  banMinh('ban_minh'),
  anhEm('anh_em'),
  chiEm('chi_em'),
  tenRieng('ten_rieng');

  const PreferredAddress(this.databaseValue);

  final String databaseValue;

  static PreferredAddress? fromDatabase(String? value) {
    for (final address in values) {
      if (address.databaseValue == value) return address;
    }
    return null;
  }
}

class OnboardingProfile {
  const OnboardingProfile({
    required this.displayName,
    required this.preferredAddress,
    required this.completedAt,
  });

  final String? displayName;
  final PreferredAddress? preferredAddress;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;
}
