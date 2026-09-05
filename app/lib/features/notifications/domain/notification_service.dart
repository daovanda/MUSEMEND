import 'package:musemend/features/notifications/domain/future_letter_reminder.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Stream<String> get journalOpenRequests;
  String? takePendingJournalId();
  Future<bool> requestPermission();
  Future<void> scheduleFutureLetter(FutureLetterReminder reminder);
  Future<void> cancelFutureLetter(String journalId);
}
