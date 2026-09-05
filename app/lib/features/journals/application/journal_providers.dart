import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/journals/data/supabase_journal_repository.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return SupabaseJournalRepository(ref.watch(supabaseClientProvider));
});

final journalControllerProvider =
    AsyncNotifierProvider<JournalController, List<JournalEntry>>(
      JournalController.new,
    );

class JournalController extends AsyncNotifier<List<JournalEntry>> {
  JournalRepository get _repository => ref.read(journalRepositoryProvider);

  @override
  Future<List<JournalEntry>> build() => _repository.loadEntries();

  Future<bool> saveDaily({
    String? id,
    required String title,
    required String content,
  }) => _mutate(
    () => _repository.saveDaily(id: id, title: title, content: content),
  );

  Future<bool> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
  }) => _mutate(
    () => _repository.saveFutureLetter(
      id: id,
      title: title,
      content: content,
      deliverAt: deliverAt,
    ),
  );

  Future<bool> open(String id) =>
      _mutate(() => _repository.openFutureLetter(id));

  Future<bool> delete(String id) => _mutate(() => _repository.delete(id));

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
