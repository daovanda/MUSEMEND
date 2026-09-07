import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/mood_visuals.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the exported sky mascot asset', () async {
    final data = await rootBundle.load(
      'assets/illustrations/clouds/mascot-cloud.png',
    );

    expect(data.lengthInBytes, greaterThan(0));
  });

  test('loads the exported sky scene asset', () async {
    final data = await rootBundle.load(
      'assets/illustrations/journey/sky-background.png',
    );

    expect(data.lengthInBytes, greaterThan(0));
  });

  test('maps every database mood to an exported Home cloud asset', () async {
    for (final mood in Mood.values) {
      final visual = mood.visual;
      final data = await rootBundle.load(visual.assetPath);

      expect(visual.label, isNotEmpty, reason: mood.databaseValue);
      expect(data.lengthInBytes, greaterThan(0), reason: visual.assetPath);
    }
  });
}
