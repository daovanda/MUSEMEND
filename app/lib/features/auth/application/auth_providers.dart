import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/auth/data/supabase_auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';

/// Enables the callback-only experience for the public Vercel deployment.
/// Flutter Web local remains the full app by default so it can still be used
/// for QA; hosted callback builds opt in explicitly at compile time.
final publicAuthPortalModeProvider = Provider<bool>(
  (ref) =>
      const bool.fromEnvironment('PUBLIC_AUTH_PORTAL', defaultValue: false),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
});

final authSessionProvider = StreamProvider<AuthSession?>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<bool> signIn({required String email, required String password}) async {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signIn(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
    required String emailRedirectTo,
  }) async {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .signUp(
            displayName: displayName,
            email: email,
            password: password,
            languageCode: languageCode,
            emailRedirectTo: emailRedirectTo,
          ),
    );
  }

  Future<bool> requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {
    return _run(
      () => ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: email, redirectTo: redirectTo),
    );
  }

  Future<bool> verifyEmailConfirmation({required String tokenHash}) => _run(
    () => ref
        .read(authRepositoryProvider)
        .verifyEmailConfirmation(tokenHash: tokenHash),
  );

  Future<bool> verifyPasswordRecovery({required String tokenHash}) => _run(
    () => ref
        .read(authRepositoryProvider)
        .verifyPasswordRecovery(tokenHash: tokenHash),
  );

  Future<bool> updatePassword({required String password}) async {
    return _run(
      () => ref.read(authRepositoryProvider).updatePassword(password: password),
    );
  }

  Future<bool> signOut() =>
      _run(() => ref.read(authRepositoryProvider).signOut());

  Future<bool> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}
