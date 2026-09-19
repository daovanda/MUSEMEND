import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_failure.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  // A restored token must not keep the splash screen blocked indefinitely when
  // the Auth endpoint is unavailable (or the account was deleted remotely).
  static const restoredSessionValidationTimeout = Duration(seconds: 15);

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

  @override
  Stream<AuthSession?> watchSession() async* {
    final restoredSession = _client.auth.currentSession;
    if (restoredSession == null) {
      yield null;
    } else {
      try {
        final response = await _client.auth
            .getUser(restoredSession.accessToken)
            .timeout(restoredSessionValidationTimeout);
        final remoteUser = response.user;
        if (remoteUser == null || remoteUser.id != restoredSession.user.id) {
          _clearInvalidRestoredSession();
          yield null;
        } else {
          yield _mapSession(restoredSession);
        }
      } on AuthException catch (error) {
        if (!shouldClearRestoredSession(error)) rethrow;
        _clearInvalidRestoredSession();
        yield null;
      } on TimeoutException {
        // Do not trust a token that could not be validated during startup.
        // Clearing the local session lets the router reach sign-in; the
        // fire-and-forget cleanup cannot hold the auth stream hostage.
        _clearInvalidRestoredSession();
        yield null;
      }
    }
    yield* _client.auth.onAuthStateChange.map(
      (event) => _mapSession(event.session),
    );
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } on AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
    required String emailRedirectTo,
  }) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: emailRedirectTo,
        data: {
          'display_name': displayName.trim(),
          // Auth email templates can use .Data.language_code to render the
          // confirmation/recovery copy in the user's current language.
          'language_code': languageCode,
        },
      );
    } on AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } on AuthException catch (_) {
      throw AuthFailure(AuthFailureCode.passwordResetFailed);
    }
  }

  @override
  Future<void> verifyEmailConfirmation({required String tokenHash}) async {
    try {
      await _client.auth.verifyOTP(tokenHash: tokenHash, type: OtpType.email);
    } on AuthException {
      throw const AuthFailure(AuthFailureCode.emailConfirmationFailed);
    }
  }

  @override
  Future<void> verifyPasswordRecovery({required String tokenHash}) async {
    try {
      final response = await _client.auth.verifyOTP(
        tokenHash: tokenHash,
        type: OtpType.recovery,
      );
      if (response.session == null) {
        throw const AuthFailure(AuthFailureCode.passwordResetFailed);
      }
    } on AuthException {
      throw const AuthFailure(AuthFailureCode.passwordResetFailed);
    }
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.email,
      );
    } on AuthException {
      throw const AuthFailure(AuthFailureCode.emailConfirmationFailed);
    }
  }

  @override
  Future<void> verifyPasswordRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: otp.trim(),
        type: OtpType.recovery,
      );
      if (response.session == null) {
        throw const AuthFailure(AuthFailureCode.passwordResetFailed);
      }
    } on AuthException {
      throw const AuthFailure(AuthFailureCode.passwordResetFailed);
    }
  }

  @override
  Future<void> updatePassword({required String password}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (_) {
      throw AuthFailure(AuthFailureCode.passwordResetFailed);
    }
  }

  @override
  Future<void> updateLanguageCode({required String languageCode}) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'language_code': languageCode}),
      );
    } catch (_) {
      // Email language metadata is helpful personalization, not an auth gate.
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  void _clearInvalidRestoredSession() {
    // gotrue removes its local session before awaiting the server revoke call.
    // Deliberately do not await it here: a deleted user can make that endpoint
    // slow or unreachable, and startup must still publish the signed-out state.
    unawaited(_client.auth.signOut().catchError((_) {}));
  }

  AuthSession? _mapSession(Session? session) {
    if (session == null) return null;
    return AuthSession(userId: session.user.id, email: session.user.email);
  }

  AuthFailure _mapFailure(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return const AuthFailure(AuthFailureCode.invalidCredentials);
    }
    if (message.contains('already registered')) {
      return const AuthFailure(AuthFailureCode.emailAlreadyRegistered);
    }
    if (message.contains('email not confirmed')) {
      return const AuthFailure(AuthFailureCode.emailNotConfirmed);
    }
    if (message.contains('password')) {
      return const AuthFailure(AuthFailureCode.weakPassword);
    }
    return const AuthFailure(AuthFailureCode.unknown);
  }
}

@visibleForTesting
bool shouldClearRestoredSession(AuthException error) {
  if (error is AuthRetryableFetchException) return false;
  if (const {'401', '403', '404'}.contains(error.statusCode)) return true;
  return const {
    'bad_jwt',
    'user_not_found',
    'session_not_found',
    'session_expired',
    'session_missing',
  }.contains(error.code);
}
