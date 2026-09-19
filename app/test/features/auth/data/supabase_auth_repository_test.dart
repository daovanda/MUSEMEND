import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:musemend/features/auth/domain/auth_failure.dart';
import 'package:musemend/features/auth/data/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('email confirmation sends token hash with the email OTP type', () async {
    final requests = <Map<String, dynamic>>[];
    final repository = _repositoryForInvalidToken(requests);

    await expectLater(
      repository.verifyEmailConfirmation(tokenHash: 'email-token-hash'),
      throwsA(isA<AuthFailure>()),
    );

    expect(requests.single['token_hash'], 'email-token-hash');
    expect(requests.single['type'], 'email');
  });

  test('password recovery sends token hash with recovery type', () async {
    final requests = <Map<String, dynamic>>[];
    final repository = _repositoryForInvalidToken(requests);

    await expectLater(
      repository.verifyPasswordRecovery(tokenHash: 'recovery-token-hash'),
      throwsA(isA<AuthFailure>()),
    );

    expect(requests.single['token_hash'], 'recovery-token-hash');
    expect(requests.single['type'], 'recovery');
  });

  test('password recovery OTP sends email, code and recovery type', () async {
    final requests = <Map<String, dynamic>>[];
    final repository = _repositoryForInvalidToken(requests);

    await expectLater(
      repository.verifyPasswordRecoveryOtp(
        email: 'qa@example.com',
        otp: '123456',
      ),
      throwsA(isA<AuthFailure>()),
    );

    expect(requests.single['email'], 'qa@example.com');
    expect(requests.single['token'], '123456');
    expect(requests.single['type'], 'recovery');
  });

  test('email confirmation OTP sends email, code and email type', () async {
    final requests = <Map<String, dynamic>>[];
    final repository = _repositoryForInvalidToken(requests);

    await expectLater(
      repository.verifyEmailOtp(email: 'qa@example.com', otp: '654321'),
      throwsA(isA<AuthFailure>()),
    );

    expect(requests.single['email'], 'qa@example.com');
    expect(requests.single['token'], '654321');
    expect(requests.single['type'], 'email');
  });

  group('shouldClearRestoredSession', () {
    test('clears sessions rejected by the Auth server', () {
      expect(
        shouldClearRestoredSession(
          const AuthException(
            'User no longer exists',
            statusCode: '403',
            code: 'user_not_found',
          ),
        ),
        isTrue,
      );
      expect(
        shouldClearRestoredSession(
          const AuthException(
            'Session expired',
            statusCode: '400',
            code: 'session_expired',
          ),
        ),
        isTrue,
      );
    });

    test('keeps the local session for retryable connectivity failures', () {
      expect(
        shouldClearRestoredSession(
          AuthRetryableFetchException(message: 'Network unavailable'),
        ),
        isFalse,
      );
      expect(
        shouldClearRestoredSession(
          const AuthException('Server unavailable', statusCode: '500'),
        ),
        isFalse,
      );
    });
  });
}

SupabaseAuthRepository _repositoryForInvalidToken(
  List<Map<String, dynamic>> requests,
) {
  final client = SupabaseClient(
    'https://auth-test.supabase.co',
    'test-publishable-key',
    httpClient: MockClient((request) async {
      requests.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response('{"msg":"Token has expired or is invalid"}', 400);
    }),
  );
  return SupabaseAuthRepository(client);
}
