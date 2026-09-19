import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/auth/presentation/password_reset_screen.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('submits the new password and returns to sign in', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final repository = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const PasswordResetScreen(),
        ),
        GoRoute(
          path: '/sign-in',
          builder:
              (context, state) => const Scaffold(body: Text('sign-in-target')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tạo mật khẩu mới cho tài khoản MuseMend của bạn.'),
      findsOneWidget,
    );
    expect(
      find.text('Nhập email để nhận liên kết đặt lại mật khẩu.'),
      findsNothing,
    );
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'MuseMend-QA-passphrase');
    await tester.enterText(fields.at(1), 'MuseMend-QA-passphrase');
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(repository.updatedPassword, 'MuseMend-QA-passphrase');
    expect(repository.didSignOut, isTrue);
    expect(find.text('sign-in-target'), findsOneWidget);
  });

  testWidgets('does not show the password form without a recovery session', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final repository = _FakeAuthRepository(withSession: false);
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (context, state) => const PasswordResetScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Liên kết không hợp lệ hoặc đã hết hạn'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.withSession = true});

  final bool withSession;
  static const session = AuthSession(
    userId: '00000000-0000-4000-8000-000000000001',
    email: 'qa@example.com',
  );
  String? updatedPassword;
  var didSignOut = false;

  @override
  AuthSession? get currentSession => withSession ? session : null;

  @override
  Future<void> requestPasswordReset({
    required String email,
    required String redirectTo,
  }) async {}

  @override
  Future<void> verifyEmailConfirmation({required String tokenHash}) async {}

  @override
  Future<void> verifyPasswordRecovery({required String tokenHash}) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    didSignOut = true;
  }

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
    required String emailRedirectTo,
  }) async {}

  @override
  Future<void> updateLanguageCode({required String languageCode}) async {}

  @override
  Future<void> updatePassword({required String password}) async {
    updatedPassword = password;
  }

  @override
  Stream<AuthSession?> watchSession() => Stream.value(currentSession);
}
