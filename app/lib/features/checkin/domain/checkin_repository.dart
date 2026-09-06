import 'package:musemend/features/checkin/domain/app_visit.dart';
import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

abstract interface class CheckinRepository {
  Future<DailyCheckin?> loadToday();

  Future<AppVisit> recordAppOpen();

  Future<DailyCheckin> saveToday({
    required Mood mood,
    required int? energyLevel,
    required String? note,
  });
}
