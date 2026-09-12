enum PreferredAddress {
  cauMinh('cau_minh', 'cậu / mình'),
  banMinh('ban_minh', 'bạn / mình'),
  anhEm('anh_em', 'anh / em'),
  chiEm('chi_em', 'chị / em'),
  tenRieng('ten_rieng', 'tên riêng');

  const PreferredAddress(this.databaseValue, this.label);

  final String databaseValue;
  final String label;

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
