import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/theme/muse_theme.dart';
import 'package:musemend/features/onboarding/application/onboarding_providers.dart';
import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';
import 'package:musemend/features/onboarding/domain/onboarding_repository.dart';
import 'package:musemend/features/onboarding/presentation/onboarding_screen.dart';

void main() {
  final repository = _PreviewOnboardingRepository();
  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(repository),
        onboardingProfileProvider.overrideWith(
          (ref) => repository.loadProfile(),
        ),
      ],
      child: const _OnboardingPreviewApp(),
    ),
  );
}

class _OnboardingPreviewApp extends StatelessWidget {
  const _OnboardingPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuseMend Onboarding Preview',
      debugShowCheckedModeBanner: false,
      theme: buildMuseTheme(),
      home: const OnboardingScreen(),
    );
  }
}

class _PreviewOnboardingRepository implements OnboardingRepository {
  static const _profile = OnboardingProfile(
    displayName: null,
    preferredAddress: null,
    completedAt: null,
  );

  @override
  Future<OnboardingProfile> loadProfile() async => _profile;

  @override
  Future<void> complete({
    required String? displayName,
    required PreferredAddress? preferredAddress,
  }) async {
    // The preview deliberately does not persist or send personal data.
  }
}
