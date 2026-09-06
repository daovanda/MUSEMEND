import 'package:musemend/features/checkin/domain/mood.dart';

class DailyCheckin {
  const DailyCheckin({
    required this.id,
    required this.checkinDate,
    required this.mood,
    required this.energyLevel,
    required this.note,
  });

  final String id;
  final DateTime checkinDate;
  final Mood mood;
  final int? energyLevel;
  final String? note;
}
