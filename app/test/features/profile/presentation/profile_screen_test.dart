import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/app/theme/muse_theme.dart';
import 'package:musemend/core/presentation/muse_ui.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/notifications/domain/inbox_notification.dart';
import 'package:musemend/features/notifications/domain/notification_repository.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';
import 'package:musemend/features/profile/domain/account_overview.dart';
import 'package:musemend/features/profile/domain/account_profile.dart';
import 'package:musemend/features/profile/domain/account_settings.dart';
import 'package:musemend/features/profile/domain/profile_repository.dart';
import 'package:musemend/features/profile/presentation/profile_screen.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('expands settings, privacy, and terms inside their cards', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          profileRepositoryProvider.overrideWithValue(_FakeProfileRepository()),
          notificationRepositoryProvider.overrideWithValue(
            _FakeNotificationRepository(),
          ),
        ],
        child: MaterialApp(
          theme: buildMuseTheme(),
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await _pumpUi(tester);

    await tester.tap(find.text('Chỉnh sửa hồ sơ và cài đặt'));
    await _pumpUi(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Tên hiển thị'), findsOneWidget);
    expect(find.text('Tên của Mây'), findsWidgets);
    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    expect(textFields, hasLength(2));
    expect(
      textFields.every((field) => field.decoration?.labelText == null),
      isTrue,
    );

    await tester.tap(find.text('Tiếng Việt'));
    await _pumpUi(tester);
    expect(find.text('日本語'), findsOneWidget);
    await tester.tap(find.text('日本語'));
    await _pumpUi(tester);
    expect(find.text('日本語'), findsOneWidget);

    await tester.tap(find.text('Sáng'));
    await _pumpUi(tester);
    expect(find.text('Tối'), findsOneWidget);
    await tester.tap(find.text('Tối'));
    await _pumpUi(tester);
    expect(find.text('Tối'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final accountCard = find.byType(MuseGlassCard).at(0);
    final saveButton = find.widgetWithText(FilledButton, 'Lưu');
    expect(
      tester.getBottomRight(accountCard).dy,
      greaterThanOrEqualTo(tester.getBottomRight(saveButton).dy),
    );

    final privacy = find.text('Quyền riêng tư');
    await tester.scrollUntilVisible(
      privacy,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(privacy);
    await _pumpUi(tester);

    expect(find.textContaining('Nhật ký được lưu riêng tư'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    final terms = find.text('Điều khoản và giới hạn');
    await tester.scrollUntilVisible(
      terms,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(terms);
    await _pumpUi(tester);

    expect(find.textContaining('MuseMend là công cụ hỗ trợ'), findsOneWidget);
    expect(find.textContaining('Nhật ký được lưu riêng tư'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

class _FakeAuthRepository implements AuthRepository {
  static const session = AuthSession(
    userId: '00000000-0000-4000-8000-000000000001',
    email: 'qa@example.com',
  );

  @override
  AuthSession? get currentSession => session;

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
  Stream<AuthSession?> watchSession() => Stream.value(session);
}

class _FakeProfileRepository implements ProfileRepository {
  final overview = const AccountOverview(
    profile: AccountProfile(displayName: 'QA', accountStatus: 'active'),
    settings: AccountSettings(
      cloudName: 'Mây Nhỏ',
      themeMode: 'light',
      soundEnabled: true,
      notificationEnabled: true,
      languageCode: 'vi',
    ),
  );

  @override
  Future<AccountOverview> loadOverview() async => overview;

  @override
  Future<void> requestAccountDeletion() async {}

  @override
  Future<void> updateProfileSettings({
    required String? displayName,
    required String cloudName,
    required String themeMode,
    required bool soundEnabled,
    required bool notificationEnabled,
    required String? languageCode,
  }) async {}
}

class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<List<InboxNotification>> loadInbox() async => const [];

  @override
  Future<void> markRead(String notificationId) async {}
}
