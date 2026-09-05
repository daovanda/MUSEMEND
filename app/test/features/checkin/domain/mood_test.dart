import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

void main() {
  test('maps all database mood values without changing server scores', () {
    for (final mood in Mood.values) {
      expect(Mood.fromDatabase(mood.databaseValue), mood);
    }

    expect(Mood.awful.score, 1);
    expect(Mood.great.score, 5);
  });

  test('rejects an unknown database mood', () {
    expect(() => Mood.fromDatabase('unknown'), throwsFormatException);
  });
}
