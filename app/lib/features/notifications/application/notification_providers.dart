import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/features/notifications/data/local_notification_service.dart';
import 'package:musemend/features/notifications/data/supabase_notification_repository.dart';
import 'package:musemend/features/notifications/domain/inbox_notification.dart';
import 'package:musemend/features/notifications/domain/notification_repository.dart';
import 'package:musemend/features/notifications/domain/notification_service.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/auth/application/auth_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

final initialNotificationJournalIdProvider = Provider<String?>((ref) => null);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return SupabaseNotificationRepository(ref.watch(supabaseClientProvider));
});

final notificationInboxProvider =
    AsyncNotifierProvider<NotificationInboxController, List<InboxNotification>>(
      NotificationInboxController.new,
    );

class NotificationInboxController
    extends AsyncNotifier<List<InboxNotification>> {
  NotificationRepository get _repository =>
      ref.read(notificationRepositoryProvider);

  @override
  Future<List<InboxNotification>> build() async {
    final userId = ref.watch(authSessionProvider).value?.userId;
    if (userId == null) return const [];
    return _repository.loadInbox();
  }

  Future<bool> open(InboxNotification notification) async {
    if (notification.isUnread) {
      try {
        await _repository.markRead(notification.id);
        state = AsyncData(await _repository.loadInbox());
      } catch (error, stackTrace) {
        state = AsyncError(error, stackTrace);
        return false;
      }
    }
    return true;
  }
}
