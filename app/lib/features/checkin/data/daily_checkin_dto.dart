import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

class DailyCheckinDto {
  const DailyCheckinDto({
    required this.id,
    required this.checkinDate,
    required this.mood,
    required this.energyLevel,
    required this.noteShort,
  });

  factory DailyCheckinDto.fromMap(Map<String, dynamic> row) {
    return DailyCheckinDto(
      id: row['id'] as String,
      checkinDate: DateTime.parse(row['checkin_date'] as String),
      mood: row['mood'] as String,
      energyLevel: (row['energy_level'] as num?)?.toInt(),
      noteShort: row['note_short'] as String?,
    );
  }

  final String id;
  final DateTime checkinDate;
  final String mood;
  final int? energyLevel;
  final String? noteShort;

  DailyCheckin toDomain() {
    return DailyCheckin(
      id: id,
      checkinDate: checkinDate,
      mood: Mood.fromDatabase(mood),
      energyLevel: energyLevel,
      note: noteShort,
    );
  }
}
