import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/domain/sky_day.dart';

void main() {
  test('check-in opens at 12:00 Vietnam time, not device time', () {
    expect(canCheckInAt(DateTime.utc(2026, 9, 27, 4, 59)), isFalse);
    expect(canCheckInAt(DateTime.utc(2026, 9, 27, 5)), isTrue);
    expect(canCheckInAt(DateTime.utc(2026, 9, 27, 16, 59)), isTrue);
    expect(canCheckInAt(DateTime.utc(2026, 9, 27, 17)), isFalse);
  });

  test('sky messages keep one index throughout the Vietnam day', () {
    expect(
      skyDayNumber(DateTime.utc(2026, 9, 27, 0)),
      skyDayNumber(DateTime.utc(2026, 9, 27, 16, 59)),
    );
    expect(
      skyDayNumber(DateTime.utc(2026, 9, 27, 17)),
      skyDayNumber(DateTime.utc(2026, 9, 27, 16, 59)) + 1,
    );
  });

  test('next refresh occurs at local noon or midnight', () {
    expect(
      nextSkyBoundary(DateTime.utc(2026, 9, 27, 4, 59)),
      DateTime.utc(2026, 9, 27, 5),
    );
    expect(
      nextSkyBoundary(DateTime.utc(2026, 9, 27, 5)),
      DateTime.utc(2026, 9, 27, 17),
    );
  });
}
