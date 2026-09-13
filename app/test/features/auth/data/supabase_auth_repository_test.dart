import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/auth/data/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
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
