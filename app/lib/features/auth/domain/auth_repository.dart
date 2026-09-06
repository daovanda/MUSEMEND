import 'package:musemend/features/auth/domain/auth_session.dart';

abstract interface class AuthRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> watchSession();

  Future<void> signIn({required String email, required String password});

  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}
