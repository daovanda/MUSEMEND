import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';

abstract interface class JournalRepository {
  Future<List<JournalEntry>> loadEntries();

  Future<String> saveDaily({
    String? id,
    required String title,
    required String content,
    required List<String> tags,
  });

  Future<String> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
    required List<String> tags,
  });

  Future<void> openFutureLetter(String id);
  Future<void> attachImage(String journalId, PickedJournalImage image);
  Future<String> createMediaUrl(String storagePath);
  Future<void> delete(String id);
}
