import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/sky_daily_content.dart';
import 'package:musemend/l10n/generated/app_localizations_vi.dart';

void main() {
  final strings = AppLocalizationsVi();
  final firstDay = DateTime.utc(2026, 9, 27);

  test('morning has twenty unique stable messages', () {
    final messages = <String>{};
    for (var day = 0; day < 20; day++) {
      final instant = firstDay.add(Duration(days: day));
      messages.add(morningMessage(strings, instant));
      expect(
        morningMessage(strings, instant),
        morningMessage(strings, instant.add(const Duration(hours: 15))),
      );
    }
    expect(messages, hasLength(20));
  });

  test('each mood has twenty unique responses', () {
    for (final mood in Mood.values) {
      final messages = <String>{};
      for (var day = 0; day < 20; day++) {
        messages.add(
          moodResponse(strings, mood, firstDay.add(Duration(days: day))),
        );
      }
      expect(messages, hasLength(20), reason: mood.databaseValue);
    }
  });
}
