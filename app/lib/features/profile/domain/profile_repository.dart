import 'package:musemend/features/profile/domain/account_overview.dart';

abstract interface class ProfileRepository {
  Future<AccountOverview> loadOverview();
}
