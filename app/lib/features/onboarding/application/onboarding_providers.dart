import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/onboarding/data/supabase_onboarding_repository.dart';
import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';
import 'package:musemend/features/onboarding/domain/onboarding_repository.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return SupabaseOnboardingRepository(ref.watch(supabaseClientProvider));
});

final onboardingProfileProvider = FutureProvider<OnboardingProfile?>((
  ref,
) async {
  final userId = ref.watch(authSessionProvider).value?.userId;
  if (userId == null) return null;
  return ref.watch(onboardingRepositoryProvider).loadProfile();
});

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, AsyncValue<void>>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> complete({
    required String? displayName,
    required PreferredAddress? preferredAddress,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(onboardingRepositoryProvider)
          .complete(
            displayName: displayName,
            preferredAddress: preferredAddress,
          ),
    );
    if (state.hasError) return false;
    ref.invalidate(onboardingProfileProvider);
    return true;
  }
}
