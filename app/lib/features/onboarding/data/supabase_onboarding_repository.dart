import 'package:musemend/features/onboarding/data/onboarding_profile_dto.dart';
import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';
import 'package:musemend/features/onboarding/domain/onboarding_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOnboardingRepository implements OnboardingRepository {
  SupabaseOnboardingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<OnboardingProfile> loadProfile() async {
    final response =
        await _client
            .from('profiles')
            .select('display_name, preferred_address, onboarding_completed_at')
            .single();
    return OnboardingProfileDto(response).toDomain();
  }

  @override
  Future<void> complete({
    required String? displayName,
    required PreferredAddress? preferredAddress,
  }) async {
    await _client.rpc(
      'complete_onboarding',
      params: {
        'p_display_name': displayName,
        'p_preferred_address': preferredAddress?.databaseValue,
      },
    );
  }
}
