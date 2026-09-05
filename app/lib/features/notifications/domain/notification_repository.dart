import 'package:musemend/features/notifications/domain/inbox_notification.dart';

abstract interface class NotificationRepository {
  Future<List<InboxNotification>> loadInbox();
  Future<void> markRead(String notificationId);
}
