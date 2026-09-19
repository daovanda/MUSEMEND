import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/auth/domain/auth_callback_token.dart';

void main() {
  test('reads one-time callback token from URL fragment', () {
    final token = AuthCallbackToken.fromUri(
      Uri.parse(
        'https://musemend-app.vercel.app/reset-password'
        '#token_hash=one-time-hash&type=recovery',
      ),
    );

    expect(token?.hash, 'one-time-hash');
    expect(token?.type, AuthCallbackType.recovery);
  });

  test('does not treat query parameters as callback credentials', () {
    final token = AuthCallbackToken.fromUri(
      Uri.parse(
        'https://musemend-app.vercel.app/email-confirmed'
        '?token_hash=must-not-be-used&type=email',
      ),
    );

    expect(token, isNull);
  });

  test('rejects unsupported or malformed callback fragments', () {
    expect(
      AuthCallbackToken.fromUri(
        Uri.parse('https://musemend-app.vercel.app/email-confirmed#type=email'),
      ),
      isNull,
    );
    expect(
      AuthCallbackToken.fromUri(
        Uri.parse(
          'https://musemend-app.vercel.app/email-confirmed'
          '#token_hash=x&type=invite',
        ),
      ),
      isNull,
    );
  });
}
