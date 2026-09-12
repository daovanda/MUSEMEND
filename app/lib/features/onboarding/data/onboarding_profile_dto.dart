import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';

class OnboardingProfileDto {
  const OnboardingProfileDto(this.data);

  final Map<String, dynamic> data;

  OnboardingProfile toDomain() => OnboardingProfile(
    displayName: data['display_name'] as String?,
    preferredAddress: PreferredAddress.fromDatabase(
      data['preferred_address'] as String?,
    ),
    completedAt:
        data['onboarding_completed_at'] == null
            ? null
            : DateTime.parse(data['onboarding_completed_at'] as String),
  );
}
