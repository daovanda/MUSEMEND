import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/app/router/app_router.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/onboarding/application/onboarding_providers.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  test('public callback portal is opt-in, preserving local web app QA', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(publicAuthPortalModeProvider), isFalse);
  });

  testWidgets('public web routes show email callbacks, never sign-in', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [
        publicAuthPortalModeProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('MuseMend — một khoảng lặng cho riêng bạn'),
      findsOneWidget,
    );
    expect(find.text('Đăng nhập'), findsNothing);

    await tester.tap(find.text('Quyền riêng tư'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Dữ liệu Google chỉ được dùng để xác thực'),
      findsOneWidget,
    );
    expect(find.text('Đăng nhập'), findsNothing);

    router.go('/terms');
    await tester.pumpAndSettle();
    expect(find.text('Điều khoản và giới hạn'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);

    router.go('/sign-in');
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsNothing);

    router.go('/email-confirmed#token_hash=signup-token&type=email');
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận email'), findsNWidgets(2));
    expect(repository.emailConfirmationTokenHash, isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận email'));
    await tester.pumpAndSettle();
    expect(repository.emailConfirmationTokenHash, 'signup-token');
    expect(find.text('Email đã được xác nhận'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);

    router.go('/reset-password#token_hash=recovery-token&type=recovery');
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.passwordRecoveryTokenHash, isNull);
    await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
    await tester.pumpAndSettle();
    expect(repository.passwordRecoveryTokenHash, 'recovery-token');
    final passwordFields = find.byType(TextFormField);
    expect(passwordFields, findsNWidgets(2));
    await tester.enterText(passwordFields.at(0), 'MuseMend-new-password');
    await tester.enterText(passwordFields.at(1), 'MuseMend-new-password');
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Đổi mật khẩu thành công'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
  });

  testWidgets('auth bootstrap does not replace the router on the OTP route', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final authEvents = StreamController<AuthSession?>();
    addTearDown(authEvents.close);
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith((ref) => authEvents.stream),
        onboardingProfileProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: container.read(appRouterProvider),
        ),
      ),
    );
    await tester.pump();

    final router = container.read(appRouterProvider);
    router.go('/confirm-email', extra: 'qa@example.com');
    await tester.pumpAndSettle();
    expect(
      find.text('Nhập email và mã 6 số trong email xác nhận từ MuseMend.'),
      findsOneWidget,
    );

    authEvents.add(null);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(container.read(appRouterProvider), same(router));
    expect(router.routeInformationProvider.value.uri.path, '/confirm-email');
    expect(
      find.text('Nhập email và mã 6 số trong email xác nhận từ MuseMend.'),
      findsOneWidget,
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  static const _session = AuthSession(
    userId: '00000000-0000-4000-8000-000000000001',
    email: 'qa@example.com',
  );
  String? emailConfirmationTokenHash;
  String? passwordRecoveryTokenHash;

  @override
  AuthSession? get currentSession => _session;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
  }) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resendEmailConfirmationOtp({required String email}) async {}

  @override
  Future<void> resendPasswordRecoveryOtp({required String email}) async {}

  @override
  Future<void> verifyEmailConfirmation({required String tokenHash}) async {
    emailConfirmationTokenHash = tokenHash;
  }

  @override
  Future<void> verifyPasswordRecovery({required String tokenHash}) async {
    passwordRecoveryTokenHash = tokenHash;
  }

  @override
  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {}

  @override
  Future<void> verifyPasswordRecoveryOtp({
    required String email,
    required String otp,
  }) async {}

  @override
  Future<void> updatePassword({required String password}) async {}

  @override
  Future<void> updateLanguageCode({required String languageCode}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<AuthSession?> watchSession() => Stream.value(_session);
}
