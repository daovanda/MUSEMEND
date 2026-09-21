import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/auth/presentation/email_confirmation_screen.dart';
import 'package:musemend/features/auth/presentation/password_reset_screen.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('verifies a sign-up OTP in app and continues to onboarding', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final repository = _FakeAuthRepository(withSession: false);
    final router = GoRouter(
      initialLocation: '/confirm-email',
      routes: [
        GoRoute(
          path: '/confirm-email',
          builder:
              (_, _) =>
                  const EmailConfirmationScreen(initialEmail: 'qa@example.com'),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const Scaffold(body: Text('onboarding-target')),
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
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'qa@example.com',
    );
    _expectOutlinedOtpFields(tester);
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận email'));
    await tester.pumpAndSettle();

    expect(find.text('onboarding-target'), findsOneWidget);
  });

  testWidgets(
    'verifies the recovery OTP, updates the password, and returns to sign in',
    (tester) async {
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
                (context, state) =>
                    const Scaffold(body: Text('sign-in-target')),
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
        find.text('Nhập email và mã 6 số trong email MuseMend mới nhất.'),
        findsOneWidget,
      );
      var fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'qa@example.com');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
      await tester.pumpAndSettle();

      fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'MuseMend-QA-passphrase');
      await tester.enterText(fields.at(1), 'MuseMend-QA-passphrase');
      _expectOutlinedOtpFields(tester);
      await tester.tap(find.text('Đổi mật khẩu'));
      await tester.pumpAndSettle();

      expect(repository.updatedPassword, 'MuseMend-QA-passphrase');
      expect(repository.didSignOut, isTrue);
      expect(find.text('sign-in-target'), findsOneWidget);
    },
  );

  testWidgets(
    'always requests a recovery OTP before showing the password form',
    (tester) async {
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

      expect(
        find.text('Nhập email và mã 6 số trong email MuseMend mới nhất.'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
      _expectOutlinedOtpFields(tester);
    },
  );

  testWidgets(
    'confirmation OTP can only be resent after the 60-second cooldown',
    (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repository = _FakeAuthRepository(withSession: false);
      final router = GoRouter(
        initialLocation: '/confirm-email',
        routes: [
          GoRoute(
            path: '/confirm-email',
            builder:
                (_, _) => const EmailConfirmationScreen(
                  initialEmail: 'qa@example.com',
                ),
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

      expect(find.text('Gửi lại mã sau 60 giây'), findsOneWidget);
      await tester.tap(find.text('Gửi lại mã sau 60 giây'));
      await tester.pump();
      expect(repository.emailOtpResendCount, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Gửi lại mã sau 59 giây'), findsOneWidget);
      await tester.pump(const Duration(seconds: 59));
      await tester.pump();
      expect(find.text('Gửi lại mã'), findsOneWidget);
      await tester.tap(find.text('Gửi lại mã'));
      await tester.pumpAndSettle();

      expect(repository.emailOtpResendCount, 1);
      expect(find.text('Gửi lại mã sau 60 giây'), findsOneWidget);
    },
  );

  testWidgets('recovery OTP resend also observes the 60-second cooldown', (
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
    await tester.enterText(find.byType(TextFormField).first, 'qa@example.com');

    expect(find.text('Gửi lại mã sau 60 giây'), findsOneWidget);
    await tester.tap(find.text('Gửi lại mã sau 60 giây'));
    await tester.pump();
    expect(repository.recoveryOtpResendCount, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại mã sau 59 giây'), findsOneWidget);
    await tester.pump(const Duration(seconds: 59));
    await tester.pump();
    expect(find.text('Gửi lại mã'), findsOneWidget);
    await tester.tap(find.text('Gửi lại mã'));
    await tester.pumpAndSettle();

    expect(repository.recoveryOtpResendCount, 1);
    expect(find.text('Gửi lại mã sau 60 giây'), findsOneWidget);
  });

  testWidgets('public portal verifies email OTP before showing password form', (
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
        overrides: [
          publicAuthPortalModeProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(repository),
        ],
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
      find.text('Nhập email và mã 6 số trong email MuseMend mới nhất.'),
      findsOneWidget,
    );
    var fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    await tester.enterText(fields.at(0), 'qa@example.com');
    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    expect(repository.recoveryOtpEmail, 'qa@example.com');
    expect(repository.recoveryOtp, '123456');
    fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));
    expect(find.text('Mật khẩu mới'), findsOneWidget);
  });

  testWidgets('public portal falls back to OTP after an invalid legacy link', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    final repository = _FakeAuthRepository(
      withSession: false,
      tokenVerificationSucceeds: false,
    );
    final router = GoRouter(
      initialLocation: '/reset-password#token_hash=stale&type=recovery',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder:
              (context, state) => PasswordResetScreen(callbackUri: state.uri),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          publicAuthPortalModeProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Đổi mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.text('Liên kết không hợp lệ hoặc đã hết hạn'), findsNothing);
    expect(
      find.text('Nhập email và mã 6 số trong email MuseMend mới nhất.'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets(
    'public confirmation portal falls back to OTP after an invalid legacy link',
    (tester) async {
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repository = _FakeAuthRepository(
        withSession: false,
        emailTokenVerificationSucceeds: false,
      );
      final router = GoRouter(
        initialLocation: '/email-confirmed#token_hash=stale&type=email',
        routes: [
          GoRoute(
            path: '/email-confirmed',
            builder:
                (context, state) =>
                    EmailConfirmationScreen(callbackUri: state.uri),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            publicAuthPortalModeProvider.overrideWithValue(true),
            authRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp.router(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận email'));
      await tester.pumpAndSettle();

      expect(find.text('Liên kết không hợp lệ hoặc đã hết hạn'), findsNothing);
      expect(
        find.text('Nhập email và mã 6 số trong email xác nhận từ MuseMend.'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
    },
  );
}

void _expectOutlinedOtpFields(WidgetTester tester) {
  for (final fieldFinder in find.byType(TextField).evaluate()) {
    final field = fieldFinder.widget as TextField;
    final decoration = field.decoration!.applyDefaults(
      Theme.of(fieldFinder).inputDecorationTheme,
    );
    expect(decoration.enabledBorder, isA<OutlineInputBorder>());
    expect(decoration.focusedBorder, isA<OutlineInputBorder>());
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    this.withSession = true,
    this.tokenVerificationSucceeds = true,
    this.emailTokenVerificationSucceeds = true,
  });

  final bool withSession;
  final bool tokenVerificationSucceeds;
  final bool emailTokenVerificationSucceeds;
  static const session = AuthSession(
    userId: '00000000-0000-4000-8000-000000000001',
    email: 'qa@example.com',
  );
  String? updatedPassword;
  String? recoveryOtpEmail;
  String? recoveryOtp;
  var recoveryOtpResendCount = 0;
  var emailOtpResendCount = 0;
  var didSignOut = false;

  @override
  AuthSession? get currentSession => withSession ? session : null;

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resendEmailConfirmationOtp({required String email}) async {
    emailOtpResendCount++;
  }

  @override
  Future<void> resendPasswordRecoveryOtp({required String email}) async {
    recoveryOtpResendCount++;
  }

  @override
  Future<void> verifyEmailConfirmation({required String tokenHash}) async {
    if (!emailTokenVerificationSucceeds) throw StateError('expired');
  }

  @override
  Future<void> verifyPasswordRecovery({required String tokenHash}) async {
    if (!tokenVerificationSucceeds) throw StateError('expired');
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
  }) async {
    recoveryOtpEmail = email;
    recoveryOtp = otp;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

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
