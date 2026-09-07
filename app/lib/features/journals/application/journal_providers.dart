import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/journals/data/supabase_journal_repository.dart';
import 'package:musemend/features/journals/data/journal_image_picker.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/journals/domain/journal_repository.dart';
import 'package:musemend/features/journals/domain/journal_calendar.dart';

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

final journalCalendarProvider = FutureProvider.autoDispose<JournalCalendarData>(
  (ref) async {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final today = DateTime.utc(now.year, now.month, now.day);
    final from = DateTime.utc(today.year, today.month - 11, 1);
    final toExclusive = today.add(const Duration(days: 1));
    final results = await Future.wait<Object?>([
      ref
          .read(journalRepositoryProvider)
          .loadDailyJournals(from: from, toExclusive: toExclusive),
      ref
          .read(checkinRepositoryProvider)
          .loadHistory(from: from, toExclusive: toExclusive),
    ]);
    final journals = results[0] as List<JournalEntry>;
    final checkins = results[1] as List<DailyCheckin>;
    final journalsByDate = <String, JournalEntry>{
      for (final entry in journals)
        if (entry.entryDate != null) _dateKey(entry.entryDate!): entry,
    };
    final checkinsByDate = <String, DailyCheckin>{
      for (final checkin in checkins) _dateKey(checkin.checkinDate): checkin,
    };
    final months = <JournalCalendarMonth>[];
    for (var offset = 0; offset < 12; offset++) {
      final monthDate = DateTime.utc(today.year, today.month - offset, 1);
      final daysInMonth =
          DateTime.utc(monthDate.year, monthDate.month + 1, 0).day;
      final days = [
        for (var day = 1; day <= daysInMonth; day++)
          JournalCalendarDay(
            date: DateTime.utc(monthDate.year, monthDate.month, day),
            checkin:
                checkinsByDate[_dateKey(
                  DateTime.utc(monthDate.year, monthDate.month, day),
                )],
            journal:
                journalsByDate[_dateKey(
                  DateTime.utc(monthDate.year, monthDate.month, day),
                )],
          ),
      ];
      if (offset == 0 || days.any((day) => day.hasActivity)) {
        months.add(
          JournalCalendarMonth(
            year: monthDate.year,
            month: monthDate.month,
            days: days,
          ),
        );
      }
    }
    return JournalCalendarData(months: List.unmodifiable(months), today: today);
  },
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

  Future<JournalEntry?> loadEntry(String id) => _repository.loadEntry(id);

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

  Future<void> updateMediaTransform(JournalMedia media) =>
      _repository.updateMediaTransform(media);

  Future<bool> delete(String id) => _mutate(() => _repository.delete(id));

  Future<String?> _save(Future<String> Function() operation) async {
    state = const AsyncLoading();
    try {
      final id = await operation();
      state = AsyncData(await _repository.loadEntries());
      ref.invalidate(journalCalendarProvider);
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
      ref.invalidate(journalCalendarProvider);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
