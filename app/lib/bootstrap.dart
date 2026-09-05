import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/app/musemend_app.dart';
import 'package:musemend/core/config/app_config.dart';
import 'package:musemend/core/config/app_config_provider.dart';
import 'package:musemend/features/notifications/application/notification_providers.dart';
import 'package:musemend/features/notifications/data/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap(AppConfig config) async {
  await Supabase.initialize(
    url: config.supabaseUrl.toString(),
    publishableKey: config.supabasePublishableKey,
  );
  final notificationService = LocalNotificationService();
  try {
    await notificationService.initialize();
  } catch (_) {
    // Notification setup must never prevent access to private journal data.
  }
  final initialNotificationJournalId =
      notificationService.takePendingJournalId();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        notificationServiceProvider.overrideWithValue(notificationService),
        initialNotificationJournalIdProvider.overrideWithValue(
          initialNotificationJournalId,
        ),
      ],
      child: const MuseMendApp(),
    ),
  );
}
