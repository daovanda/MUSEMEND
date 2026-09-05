import 'package:musemend/features/notifications/domain/inbox_notification.dart';

class InboxNotificationMapper {
  const InboxNotificationMapper();

  InboxNotification fromJson(Map<String, dynamic> json) {
    return InboxNotification(
      id: json['id'] as String,
      journalId: json['journal_id'] as String,
      scheduledFor: DateTime.parse(json['scheduled_for'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt:
          json['read_at'] == null
              ? null
              : DateTime.parse(json['read_at'] as String),
    );
  }
}
