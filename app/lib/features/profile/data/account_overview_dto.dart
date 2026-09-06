import 'package:musemend/features/profile/domain/account_overview.dart';
import 'package:musemend/features/profile/domain/account_profile.dart';
import 'package:musemend/features/profile/domain/account_settings.dart';

class AccountOverviewDto {
  const AccountOverviewDto({required this.profile, required this.settings});

  final Map<String, dynamic> profile;
  final Map<String, dynamic> settings;

  AccountOverview toDomain() {
    return AccountOverview(
      profile: AccountProfile(
        displayName: profile['display_name'] as String?,
        accountStatus: profile['account_status'] as String,
      ),
      settings: AccountSettings(
        cloudName: settings['cloud_name'] as String? ?? 'Mây',
        themeMode: settings['theme_mode'] as String,
        soundEnabled: settings['sound_enabled'] as bool,
        notificationEnabled: settings['notification_enabled'] as bool,
      ),
    );
  }
}
