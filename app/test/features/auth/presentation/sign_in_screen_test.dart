import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/theme/muse_colors.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/auth/presentation/sign_in_screen.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('switches to sign-up and validates required fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignInScreen(),
        ),
      ),
    );

    expect(find.text('Chào bạn trở lại'), findsOneWidget);
    final signUpLink = find.text('Chưa có tài khoản? Đăng ký');
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pump();

    expect(find.text('Tên hiển thị'), findsOneWidget);
    final createAccountButton = find.text('Tạo tài khoản');
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pump();

    expect(find.text('Tên cần từ 2 đến 60 ký tự.'), findsOneWidget);
    expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 8 ký tự.'), findsOneWidget);
  });

  testWidgets('moves to in-app password recovery after sending an OTP', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/sign-in',
      routes: [
        GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
        GoRoute(
          path: '/reset-password',
          builder:
              (_, state) => Scaffold(body: Text('reset-target:${state.extra}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pump();
    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsNothing);
    expect(find.text('Tiếp tục với Google'), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'qa@example.com');
    await tester.tap(find.text('Gửi mã đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(repository.resetEmail, 'qa@example.com');
    expect(find.text('reset-target:qa@example.com'), findsOneWidget);
  });

  testWidgets('starts Google OAuth from both sign-in and sign-up', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SignInScreen(),
        ),
      ),
    );

    final googleButton = find.text('Tiếp tục với Google');
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pump();
    expect(repository.googleSignInRequests, 1);

    final signUpLink = find.text('Chưa có tài khoản? Đăng ký');
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pump();
    final signUpGoogleButton = find.text('Tiếp tục với Google');
    expect(signUpGoogleButton, findsOneWidget);
    await tester.ensureVisible(signUpGoogleButton);
    await tester.tap(signUpGoogleButton);
    await tester.pump();
    expect(repository.googleSignInRequests, 2);
  });

  testWidgets('moves to in-app email confirmation after sign-up', (
    tester,
  ) async {
    final repository = _FakeAuthRepository();
    final router = GoRouter(
      initialLocation: '/sign-in',
      routes: [
        GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
        GoRoute(
          path: '/confirm-email',
          builder:
              (_, state) =>
                  Scaffold(body: Text('confirmation-target:${state.extra}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    final signUpLink = find.text('Chưa có tài khoản? Đăng ký');
    await tester.ensureVisible(signUpLink);
    await tester.tap(signUpLink);
    await tester.pump();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'QA User');
    await tester.enterText(fields.at(1), 'qa@example.com');
    await tester.enterText(fields.at(2), 'MuseMend-QA-passphrase');
    final createAccountButton = find.text('Tạo tài khoản');
    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(repository.signUpEmail, 'qa@example.com');
    expect(find.text('confirmation-target:qa@example.com'), findsOneWidget);
  });

  testWidgets('remains usable on a small screen at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
          home: const SignInScreen(),
        ),
      ),
    );

    final submit = find.widgetWithText(FilledButton, 'Đăng nhập');
    await tester.ensureVisible(submit);
    await tester.pump(const Duration(milliseconds: 250));

    expect(submit, findsOneWidget);
    expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the calm light auth palette when system theme is dark', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          home: const SignInScreen(),
        ),
      ),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, MuseColors.cream);
    expect(
      find.image(
        const AssetImage('assets/illustrations/clouds/mascot-cloud.png'),
      ),
      findsOneWidget,
    );
    expect(
      find.image(
        const AssetImage('assets/illustrations/journey/sky-background.png'),
      ),
      findsOneWidget,
    );

    final emailEditor = tester.widget<EditableText>(
      find.byType(EditableText).first,
    );
    expect(emailEditor.style.color, MuseColors.ink);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stops the auth background drift when reduce motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          home: const SignInScreen(),
        ),
      ),
    );

    final drift = find.byKey(const ValueKey('auth-sky-drift'));
    final before = tester.widget<Transform>(drift).transform.clone();
    await tester.pump(const Duration(seconds: 2));
    final after = tester.widget<Transform>(drift).transform;

    expect(after.storage, orderedEquals(before.storage));
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  String? resetEmail;
  String? signUpEmail;
  var googleSignInRequests = 0;

  @override
  AuthSession? get currentSession => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async => googleSignInRequests++;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
    required String languageCode,
  }) async {
    signUpEmail = email;
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    resetEmail = email;
  }

  @override
  Future<void> resendEmailConfirmationOtp({required String email}) async {}

  @override
  Future<void> resendPasswordRecoveryOtp({required String email}) async {}

  @override
  Future<void> verifyEmailConfirmation({required String tokenHash}) async {}

  @override
  Future<void> verifyPasswordRecovery({required String tokenHash}) async {}

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
  Stream<AuthSession?> watchSession() => Stream.value(null);
}
