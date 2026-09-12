import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';

abstract interface class OnboardingRepository {
  Future<OnboardingProfile> loadProfile();

  Future<void> complete({
    required String? displayName,
    required PreferredAddress? preferredAddress,
  });
}
