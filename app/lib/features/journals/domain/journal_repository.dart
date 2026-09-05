import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';

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
  Future<void> attachImage(String journalId, PickedJournalImage image);
  Future<String> createMediaUrl(String storagePath);
  Future<void> delete(String id);
}
