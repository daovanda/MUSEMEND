import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';
import 'package:musemend/features/auth/domain/auth_repository.dart';
import 'package:musemend/features/auth/domain/auth_session.dart';
import 'package:musemend/features/auth/presentation/sign_in_screen.dart';

void main() {
  testWidgets('switches to sign-up and validates required fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: const MaterialApp(home: SignInScreen()),
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
