import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/onboarding/data/onboarding_profile_dto.dart';
import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';

void main() {
  test('maps onboarding profile fields', () {
    final profile =
        OnboardingProfileDto({
          'display_name': 'An',
          'preferred_address': 'ban_minh',
          'onboarding_completed_at': '2026-09-12T08:30:00Z',
        }).toDomain();

    expect(profile.displayName, 'An');
    expect(profile.preferredAddress, PreferredAddress.banMinh);
    expect(profile.completedAt, DateTime.utc(2026, 9, 12, 8, 30));
    expect(profile.isCompleted, isTrue);
  });

  test('keeps optional onboarding fields empty', () {
    final profile =
        OnboardingProfileDto({
          'display_name': null,
          'preferred_address': null,
          'onboarding_completed_at': null,
        }).toDomain();

    expect(profile.displayName, isNull);
    expect(profile.preferredAddress, isNull);
    expect(profile.isCompleted, isFalse);
  });
}
