import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/journals/data/supabase_journal_repository.dart';
import 'package:musemend/features/journals/data/journal_image_picker.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/journals/domain/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return SupabaseJournalRepository(ref.watch(supabaseClientProvider));
});

final journalImagePickerProvider = Provider<JournalImagePicker>((ref) {
  return JournalImagePicker();
});

final journalMediaUrlProvider = FutureProvider.autoDispose
    .family<String, String>(
      (ref, storagePath) =>
          ref.watch(journalRepositoryProvider).createMediaUrl(storagePath),
    );

final journalEntryProvider = FutureProvider.autoDispose
    .family<JournalEntry?, String>(
      (ref, id) => ref.watch(journalRepositoryProvider).loadEntry(id),
    );

final journalControllerProvider =
    AsyncNotifierProvider<JournalController, List<JournalEntry>>(
      JournalController.new,
    );

class JournalController extends AsyncNotifier<List<JournalEntry>> {
  JournalRepository get _repository => ref.read(journalRepositoryProvider);

  @override
  Future<List<JournalEntry>> build() => _repository.loadEntries();

  Future<String?> saveDaily({
    String? id,
    required String title,
    required String content,
    required List<String> tags,
  }) => _save(
    () => _repository.saveDaily(
      id: id,
      title: title,
      content: content,
      tags: tags,
    ),
  );

  Future<String?> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
    required List<String> tags,
  }) => _save(
    () => _repository.saveFutureLetter(
      id: id,
      title: title,
      content: content,
      deliverAt: deliverAt,
      tags: tags,
    ),
  );

  Future<bool> open(String id) =>
      _mutate(() => _repository.openFutureLetter(id));

  Future<JournalImageResult> attachImage(String journalId) async {
    try {
      final (result, image) = await ref.read(journalImagePickerProvider).pick();
      if (result != JournalImageResult.success || image == null) return result;
      state = const AsyncLoading();
      await _repository.attachImage(journalId, image);
      state = AsyncData(await _repository.loadEntries());
      return JournalImageResult.success;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return JournalImageResult.failed;
    }
  }

  Future<bool> delete(String id) => _mutate(() => _repository.delete(id));

  Future<String?> _save(Future<String> Function() operation) async {
    state = const AsyncLoading();
    try {
      final id = await operation();
      state = AsyncData(await _repository.loadEntries());
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.loadEntries);
  }

  Future<bool> _mutate(Future<void> Function() operation) async {
    state = const AsyncLoading();
    try {
      await operation();
      state = AsyncData(await _repository.loadEntries());
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
