import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/profile/data/account_overview_dto.dart';

void main() {
  test('maps bootstrapped profile and settings', () {
    final overview =
        AccountOverviewDto(
          profile: {'display_name': 'Demo', 'account_status': 'active'},
          settings: {
            'cloud_name': 'Mây Nhỏ',
            'theme_mode': 'system',
            'sound_enabled': true,
            'notification_enabled': false,
          },
        ).toDomain();

    expect(overview.profile.displayName, 'Demo');
    expect(overview.profile.accountStatus, 'active');
    expect(overview.settings.cloudName, 'Mây Nhỏ');
    expect(overview.settings.notificationEnabled, isFalse);
  });
}
