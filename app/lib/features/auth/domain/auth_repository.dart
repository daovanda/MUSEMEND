import 'package:musemend/features/auth/domain/auth_session.dart';

abstract interface class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> watchSession();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
    required String emailRedirectTo,
  });

  Future<void> requestPasswordReset({
    required String email,
    required String redirectTo,
  });

  Future<void> verifyEmailConfirmation({required String tokenHash});

  Future<void> verifyPasswordRecovery({required String tokenHash});

  Future<void> verifyEmailOtp({required String email, required String otp});

  Future<void> verifyPasswordRecoveryOtp({
    required String email,
    required String otp,
  });

  Future<void> updatePassword({required String password});

  Future<void> updateLanguageCode({required String languageCode});

  Future<void> signOut();
}
