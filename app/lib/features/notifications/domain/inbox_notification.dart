class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.journalId,
    required this.scheduledFor,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String journalId;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;
}
