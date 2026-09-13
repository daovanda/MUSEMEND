import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pump();

    expect(find.text('Tên hiển thị'), findsOneWidget);
    await tester.tap(find.text('Tạo tài khoản'));
    await tester.pump();

    expect(find.text('Tên cần từ 2 đến 60 ký tự.'), findsOneWidget);
    expect(find.text('Email chưa đúng định dạng.'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 8 ký tự.'), findsOneWidget);
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
  @override
  AuthSession? get currentSession => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {}

  @override
  Stream<AuthSession?> watchSession() => Stream.value(null);
}
