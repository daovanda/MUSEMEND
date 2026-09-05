import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/core/config/app_config.dart';

void main() {
  group('AppConfig.parse', () {
    test('accepts an HTTPS Supabase configuration', () {
      final config = AppConfig.parse(
        environment: 'development',
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'publishable-key',
      );

      expect(config.environment, AppEnvironment.development);
      expect(config.supabaseUrl.host, 'example.supabase.co');
    });

    test('rejects insecure URLs', () {
      expect(
        () => AppConfig.parse(
          environment: 'production',
          supabaseUrl: 'http://example.supabase.co',
          supabasePublishableKey: 'publishable-key',
        ),
        throwsArgumentError,
      );
    });

    test('rejects an empty publishable key', () {
      expect(
        () => AppConfig.parse(
          environment: 'development',
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: ' ',
        ),
        throwsArgumentError,
      );
    });
  });
}
