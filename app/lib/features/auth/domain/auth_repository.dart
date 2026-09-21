import 'package:musemend/features/auth/domain/auth_session.dart';

abstract interface class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> watchSession();

  Future<void> signIn({required String email, required String password});

  /// Starts the Google OAuth flow. On Android/iOS the provider returns to the
  /// application's registered deep link; Flutter Web returns to its origin.
  Future<void> signInWithGoogle();

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
  });

  Future<void> requestPasswordReset({required String email});

  Future<void> resendEmailConfirmationOtp({required String email});

  Future<void> resendPasswordRecoveryOtp({required String email});

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
