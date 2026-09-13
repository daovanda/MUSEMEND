class FutureLetterReminder {
  const FutureLetterReminder({
    required this.journalId,
    required this.deliverAt,
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String journalId;
  final DateTime deliverAt;
  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
}
