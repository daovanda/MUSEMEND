import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/domain/app_visit.dart';
import 'package:musemend/features/checkin/domain/checkin_repository.dart';
import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

void main() {
  test('updateMood preserves existing energy and note', () async {
    final repository = _RecordingCheckinRepository();
    final container = ProviderContainer(
      overrides: [checkinRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(reflectControllerProvider.future);
    final saved = await container
        .read(reflectControllerProvider.notifier)
        .updateMood(Mood.good);

    expect(saved, isTrue);
    expect(repository.savedMood, Mood.good);
    expect(repository.savedEnergyLevel, 4);
    expect(repository.savedNote, 'Một ghi chú cần được giữ lại');
  });
}

class _RecordingCheckinRepository implements CheckinRepository {
  Mood? savedMood;
  int? savedEnergyLevel;
  String? savedNote;

  final checkin = DailyCheckin(
    id: 'checkin-1',
    checkinDate: DateTime.utc(2026, 9, 7),
    mood: Mood.okay,
    energyLevel: 4,
    note: 'Một ghi chú cần được giữ lại',
  );

  @override
  Future<DailyCheckin?> loadToday() async => checkin;

  @override
  Future<List<DailyCheckin>> loadHistory({
    required DateTime from,
    required DateTime toExclusive,
  }) async => [];

  @override
  Future<AppVisit> recordAppOpen() async {
    return AppVisit(visitDate: DateTime.utc(2026, 9, 7), streak: 3);
  }

  @override
  Future<DailyCheckin> saveToday({
    required Mood mood,
    required int? energyLevel,
    required String? note,
  }) async {
    savedMood = mood;
    savedEnergyLevel = energyLevel;
    savedNote = note;
    return DailyCheckin(
      id: checkin.id,
      checkinDate: checkin.checkinDate,
      mood: mood,
      energyLevel: energyLevel,
      note: note,
    );
  }
}
