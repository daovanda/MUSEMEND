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

    await tester.enterText(find.byType(TextField), 'Tên trong onboarding');
    await tester.tap(find.text('bạn / mình'));
    await tester.tap(find.text('Bắt đầu cùng Muse'));
    await _pumpUi(tester);

    expect(repository.savedDisplayName, 'Tên trong onboarding');
    expect(repository.savedAddress, PreferredAddress.banMinh);
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
  Future<void> signOut() async => didSignOut = true;

  @override
  Future<void> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {}

  @override
  Stream<AuthSession?> watchSession() => Stream.value(null);
}
