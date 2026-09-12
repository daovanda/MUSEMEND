class AccountSettings {
  const AccountSettings({
    required this.cloudName,
    required this.themeMode,
    required this.soundEnabled,
    required this.notificationEnabled,
    required this.languageCode,
  });

  final String cloudName;
  final String themeMode;
  final bool soundEnabled;
  final bool notificationEnabled;
  final String? languageCode;
}
