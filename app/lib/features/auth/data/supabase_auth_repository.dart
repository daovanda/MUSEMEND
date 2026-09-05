import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_failure.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

  @override
  Stream<AuthSession?> watchSession() async* {
    yield currentSession;
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
  }) async {
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
    } on AuthException catch (error) {
      throw _mapFailure(error);
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

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
