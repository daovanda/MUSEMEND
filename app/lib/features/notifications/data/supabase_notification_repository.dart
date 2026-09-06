import 'package:musemend/features/notifications/domain/inbox_notification.dart';
import 'package:musemend/features/notifications/data/inbox_notification_mapper.dart';
import 'package:musemend/features/notifications/domain/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this._client);

  final SupabaseClient _client;
  static const _mapper = InboxNotificationMapper();

  @override
  Future<List<InboxNotification>> loadInbox() async {
    final response = await _client
        .from('notifications')
        .select('id, journal_id, scheduled_for, created_at, read_at')
        .order('created_at', ascending: false)
        .limit(30);
    return response.map(_mapper.fromJson).toList(growable: false);
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _client.rpc(
      'mark_notification_read',
      params: {'p_id': notificationId},
    );
  }
}
