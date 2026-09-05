import 'package:musemend/features/journals/domain/journal_entry.dart';

abstract interface class JournalRepository {
  Future<List<JournalEntry>> loadEntries();

  Future<void> saveDaily({
    String? id,
    required String title,
    required String content,
  });

  Future<void> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
  });

  Future<void> openFutureLetter(String id);
  Future<void> delete(String id);
}
