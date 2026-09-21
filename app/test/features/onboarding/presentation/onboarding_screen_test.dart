import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/onboarding/application/onboarding_providers.dart';
import 'package:musemend/features/onboarding/domain/onboarding_profile.dart';
import 'package:musemend/features/onboarding/domain/onboarding_repository.dart';
import 'package:musemend/features/onboarding/presentation/onboarding_screen.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows all onboarding messages and saves personalization', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository(
      const OnboardingProfile(
        displayName: 'Tên đăng ký',
        preferredAddress: null,
        completedAt: null,
      ),
    );
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          onboardingProfileProvider.overrideWith(
            (ref) async => repository.profile,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await _pumpUi(tester);

    expect(find.text('Gọi tên cảm xúc'), findsOneWidget);
    expect(find.text('Viết cho riêng mình'), findsOneWidget);
    expect(find.text('Chăm sóc bằng bước nhỏ'), findsOneWidget);
    expect(
      find.text(
        'Bắt đầu bằng việc nhận ra cảm xúc, viết xuống tâm tư và chăm sóc mình từng chút một.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Tiếp tục'));
    await _pumpUi(tester);
    expect(find.text('Nhật ký lưu trên thiết bị'), findsOneWidget);
    expect(find.text('Dùng được khi ngoại tuyến'), findsOneWidget);
    expect(find.text('Sao lưu là tùy chọn'), findsOneWidget);
    expect(find.text('Sắp có'), findsNothing);

    await tester.tap(find.text('Tiếp tục'));
    await _pumpUi(tester);
    expect(find.text('Mây nên gọi bạn là gì?'), findsOneWidget);
    expect(find.text('Tên đăng ký'), findsOneWidget);
    expect(find.text('Tên bạn muốn hiển thị'), findsOneWidget);
    expect(find.text('CÁCH XƯNG HÔ'), findsNothing);

    await tester.enterText(find.byType(TextField), 'Tên trong onboarding');
    await tester.tap(find.text('Bắt đầu cùng Muse'));
    await _pumpUi(tester);

    expect(repository.savedDisplayName, 'Tên trong onboarding');
    expect(repository.savedAddress, isNull);
  });

  testWidgets('skip keeps the existing display name and default address', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository(
      const OnboardingProfile(
        displayName: null,
        preferredAddress: null,
        completedAt: null,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          onboardingProfileProvider.overrideWith(
            (ref) async => repository.profile,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Bỏ qua'));
    await _pumpUi(tester);

    expect(repository.savedDisplayName, isNull);
    expect(repository.savedAddress, isNull);
  });

  testWidgets('swiping horizontally changes onboarding steps', (tester) async {
    final repository = _FakeOnboardingRepository(
      const OnboardingProfile(
        displayName: null,
        preferredAddress: null,
        completedAt: null,
      ),
    );
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          onboardingProfileProvider.overrideWith(
            (ref) async => repository.profile,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await _pumpUi(tester);

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await _pumpUi(tester);
    expect(find.text('Nhật ký lưu trên thiết bị'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(320, 0));
    await _pumpUi(tester);
    expect(find.text('Gọi tên cảm xúc'), findsOneWidget);
  });

  testWidgets('first step can return to sign in', (tester) async {
    final onboardingRepository = _FakeOnboardingRepository(
      const OnboardingProfile(
        displayName: 'Tên đăng ký',
        preferredAddress: null,
        completedAt: null,
      ),
    );
    final authRepository = _FakeAuthRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          onboardingRepositoryProvider.overrideWithValue(onboardingRepository),
          onboardingProfileProvider.overrideWith(
            (ref) async => onboardingRepository.profile,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.byTooltip('Quay lại màn đăng nhập'));
    await _pumpUi(tester);

    expect(authRepository.didSignOut, isTrue);
  });

  testWidgets(
    'steps share card position and stay light on a compact dark device',
    (tester) async {
      final repository = _FakeOnboardingRepository(
        const OnboardingProfile(
          displayName: null,
          preferredAddress: null,
          completedAt: null,
        ),
      );
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(repository),
            onboardingProfileProvider.overrideWith(
              (ref) async => repository.profile,
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await _pumpUi(tester);
      expect(
        Theme.of(tester.element(find.text('Gọi tên cảm xúc'))).brightness,
        Brightness.light,
      );
      final welcomeTop =
          tester
              .getTopLeft(
                find
                    .ancestor(
                      of: find.text('Gọi tên cảm xúc'),
                      matching: find.byType(MuseGlassCard),
                    )
                    .first,
              )
              .dy;
      final welcomeSubtitleTop =
          tester
              .getTopLeft(
                find.text(
                  'Bắt đầu bằng việc nhận ra cảm xúc, viết xuống tâm tư và chăm sóc mình từng chút một.',
                ),
              )
              .dy;
      final welcomeHeadlineTop =
          tester
              .getTopLeft(
                find.text(
                  'Một nơi để bạn lắng nghe mình, theo cách nhẹ nhàng hơn.',
                ),
              )
              .dy;
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await _pumpUi(tester);
      final privacyTop =
          tester
              .getTopLeft(
                find
                    .ancestor(
                      of: find.text('Nhật ký lưu trên thiết bị'),
                      matching: find.byType(MuseGlassCard),
                    )
                    .first,
              )
              .dy;
      expect(privacyTop, closeTo(welcomeTop, 1));
      expect(
        tester
            .getTopLeft(
              find.text(
                'MuseMend đang được xây dựng theo hướng riêng tư và chủ động.',
              ),
            )
            .dy,
        closeTo(welcomeSubtitleTop, 1),
      );
      expect(
        tester
            .getTopLeft(
              find.text('Những điều riêng tư của bạn nên thuộc về bạn.'),
            )
            .dy,
        closeTo(welcomeHeadlineTop, 1),
      );
      expect(tester.takeException(), isNull);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await _pumpUi(tester);
      final nameTop =
          tester
              .getTopLeft(
                find
                    .ancestor(
                      of: find.text('Tên bạn muốn hiển thị'),
                      matching: find.byType(MuseGlassCard),
                    )
                    .first,
              )
              .dy;
      expect(nameTop, closeTo(welcomeTop, 1));
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('Tên bạn muốn hiển thị'),
                    matching: find.byType(MuseGlassCard),
                  )
                  .first,
            )
            .height,
        closeTo(108, 1),
      );
      expect(
        tester
            .getTopLeft(
              find.text(
                'Bạn có thể đổi lại bất kỳ lúc nào trong trang Cá nhân.',
              ),
            )
            .dy,
        closeTo(welcomeSubtitleTop, 1),
      );
      expect(
        tester.getTopLeft(find.text('Mây nên gọi bạn là gì?')).dy,
        closeTo(welcomeHeadlineTop, 1),
      );
      expect(find.text('CÁCH XƯNG HÔ'), findsNothing);
      expect(find.byType(MusePill), findsNothing);
      expect(find.byIcon(Icons.waving_hand_outlined), findsOneWidget);
      final greeting = find.text(
        'Chào Bạn của Muse, rất vui được đồng hành cùng bạn!',
      );
      expect(greeting, findsOneWidget);
      expect(
        find.ancestor(of: greeting, matching: find.byType(MuseGlassCard)),
        findsNothing,
      );
      expect(
        tester.widget<Text>(greeting).style?.fontSize,
        greaterThan(
          Theme.of(tester.element(greeting)).textTheme.titleMedium?.fontSize ??
              0,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('keeps vertical anchors aligned during a partial swipe', (
    tester,
  ) async {
    final repository = _FakeOnboardingRepository(
      const OnboardingProfile(
        displayName: null,
        preferredAddress: null,
        completedAt: null,
      ),
    );
    tester.view.physicalSize = const Size(354, 879);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          onboardingProfileProvider.overrideWith(
            (ref) async => repository.profile,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OnboardingScreen(),
        ),
      ),
    );
    await _pumpUi(tester);

    final gesture = await tester.startGesture(const Offset(270, 420));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    final welcomeCard =
        find
            .ancestor(
              of: find.text('Gọi tên cảm xúc'),
              matching: find.byType(MuseGlassCard),
            )
            .first;
    final welcomeTop = tester.getTopLeft(welcomeCard).dy;
    final welcomeHeight = tester.getSize(welcomeCard).height;
    final privacyCard =
        find
            .ancestor(
              of: find.text('Nhật ký lưu trên thiết bị'),
              matching: find.byType(MuseGlassCard),
            )
            .first;
    final privacyTop = tester.getTopLeft(privacyCard).dy;
    expect(privacyTop, closeTo(welcomeTop, 1));
    expect(tester.getSize(privacyCard).height, closeTo(welcomeHeight, 1));
    final spaceBetweenCards =
        tester.getTopLeft(privacyCard).dx - tester.getTopRight(welcomeCard).dx;
    expect(spaceBetweenCards, greaterThanOrEqualTo(15));
    await gesture.up();
    await _pumpUi(tester);
    expect(tester.takeException(), isNull);
  });

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('all onboarding steps fit 360x800 in ${locale.languageCode}', (
      tester,
    ) async {
      final repository = _FakeOnboardingRepository(
        const OnboardingProfile(
          displayName: null,
          preferredAddress: null,
          completedAt: null,
        ),
      );
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onboardingRepositoryProvider.overrideWithValue(repository),
            onboardingProfileProvider.overrideWith(
              (ref) async => repository.profile,
            ),
          ],
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await _pumpUi(tester);
      expect(tester.takeException(), isNull);
      for (var step = 1; step < 3; step++) {
        await tester.drag(find.byType(PageView), const Offset(-300, 0));
        await _pumpUi(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'step $step in ${locale.languageCode}',
        );
      }
    });
  }
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 320));
}

class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository(this.profile);

  OnboardingProfile profile;
  String? savedDisplayName;
  PreferredAddress? savedAddress;

  @override
  Future<OnboardingProfile> loadProfile() async => profile;

  @override
  Future<void> complete({
    required String? displayName,
    required PreferredAddress? preferredAddress,
  }) async {
    savedDisplayName = displayName;
    savedAddress = preferredAddress;
    profile = OnboardingProfile(
      displayName: displayName ?? profile.displayName,
      preferredAddress: preferredAddress,
      completedAt: DateTime.now(),
    );
  }
}

class _FakeAuthRepository implements AuthRepository {
  bool didSignOut = false;

  @override
  AuthSession? get currentSession => null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signOut() async => didSignOut = true;

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
