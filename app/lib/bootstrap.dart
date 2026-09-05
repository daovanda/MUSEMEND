import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/musemend_app.dart';
import 'package:musemend/core/config/app_config.dart';
import 'package:musemend/core/config/app_config_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap(AppConfig config) async {
  await Supabase.initialize(
    url: config.supabaseUrl.toString(),
    publishableKey: config.supabasePublishableKey,
  );

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const MuseMendApp(),
    ),
  );
}
