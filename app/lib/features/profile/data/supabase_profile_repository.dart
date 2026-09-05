import 'package:musemend/features/profile/data/account_overview_dto.dart';
import 'package:musemend/features/profile/domain/account_overview.dart';
import 'package:musemend/features/profile/domain/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AccountOverview> loadOverview() async {
    final results = await Future.wait<Map<String, dynamic>>([
      _client.from('profiles').select('display_name, account_status').single(),
      _client
          .from('user_settings')
          .select('cloud_name, theme_mode, sound_enabled, notification_enabled')
          .single(),
    ]);
    return AccountOverviewDto(
      profile: results[0],
      settings: results[1],
    ).toDomain();
  }
}
