import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musemend/app/musemend_app.dart';
import 'package:musemend/app/router/app_router.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';

void main() {
  testWidgets('keeps the application light when the device is dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) =>
                  const Scaffold(body: SizedBox(key: Key('theme-probe'))),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedOutRepository()),
          appRouterProvider.overrideWithValue(router),
        ],
        child: const MuseMendApp(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('theme-probe')));
    expect(Theme.of(context).brightness, Brightness.light);
  });
}

class _SignedOutRepository implements AuthRepository {
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
