import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/notifications/data/inbox_notification_mapper.dart';

void main() {
  test('maps unread and read inbox notifications', () {
    const mapper = InboxNotificationMapper();
    final unread = mapper.fromJson({
      'id': 'notification-id',
      'journal_id': 'journal-id',
      'scheduled_for': '2026-09-06T02:00:00Z',
      'created_at': '2026-09-06T02:00:01Z',
      'read_at': null,
    });
    final read = mapper.fromJson({
      'id': 'read-notification-id',
      'journal_id': 'journal-id',
      'scheduled_for': '2026-09-06T02:00:00Z',
      'created_at': '2026-09-06T02:00:01Z',
      'read_at': '2026-09-06T03:00:00Z',
    });

    expect(unread.isUnread, isTrue);
    expect(unread.scheduledFor.toUtc(), DateTime.utc(2026, 9, 6, 2));
    expect(read.isUnread, isFalse);
  });
}
