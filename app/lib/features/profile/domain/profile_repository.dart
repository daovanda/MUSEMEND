import 'package:musemend/features/profile/domain/account_overview.dart';

abstract interface class ProfileRepository {
  Future<AccountOverview> loadOverview();
  Future<void> updateProfileSettings({
    required String? displayName,
    required String cloudName,
    required String themeMode,
    required bool soundEnabled,
    required bool notificationEnabled,
  });
  Future<void> requestAccountDeletion();
}
