import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/data/daily_checkin_dto.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

void main() {
  test('maps the note_short database column to the domain note', () {
    final checkin =
        DailyCheckinDto.fromMap({
          'id': '10000000-0000-4000-8000-000000000001',
          'checkin_date': '2026-09-05',
          'mood': 'good',
          'energy_level': 4,
          'note_short': 'Một ngày dịu dàng',
        }).toDomain();

    expect(checkin.mood, Mood.good);
    expect(checkin.energyLevel, 4);
    expect(checkin.note, 'Một ngày dịu dàng');
  });
}
