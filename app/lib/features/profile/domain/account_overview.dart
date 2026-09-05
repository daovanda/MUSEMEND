import 'package:musemend/features/profile/domain/account_profile.dart';
import 'package:musemend/features/profile/domain/account_settings.dart';

class AccountOverview {
  const AccountOverview({required this.profile, required this.settings});

  final AccountProfile profile;
  final AccountSettings settings;
}
