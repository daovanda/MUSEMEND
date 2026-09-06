enum AppEnvironment { development, production }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig.parse(
      environment: const String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey: const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      ),
    );
  }

  factory AppConfig.parse({
    required String environment,
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) {
    final parsedEnvironment = switch (environment.trim().toLowerCase()) {
      'development' => AppEnvironment.development,
      'production' => AppEnvironment.production,
      _ =>
        throw ArgumentError.value(environment, 'APP_ENV', 'Unsupported value'),
    };
    final parsedUrl = Uri.tryParse(supabaseUrl.trim());
    if (parsedUrl == null ||
        parsedUrl.scheme != 'https' ||
        parsedUrl.host.isEmpty) {
      throw ArgumentError.value(
        supabaseUrl,
        'SUPABASE_URL',
        'A valid HTTPS Supabase URL is required',
      );
    }
    final key = supabasePublishableKey.trim();
    if (key.isEmpty) {
      throw ArgumentError('SUPABASE_PUBLISHABLE_KEY is required');
    }

    return AppConfig(
      environment: parsedEnvironment,
      supabaseUrl: parsedUrl,
      supabasePublishableKey: key,
    );
  }

  final AppEnvironment environment;
  final Uri supabaseUrl;
  final String supabasePublishableKey;
}
