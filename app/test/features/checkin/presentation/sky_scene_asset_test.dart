import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/checkin/presentation/mood_visuals.dart';
import 'package:musemend/features/checkin/presentation/sky_scene.dart';

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

  testWidgets(
    'sky scene fills the hero constraints instead of a fixed height',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 625,
                child: Stack(children: [Positioned.fill(child: SkyScene())]),
              ),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(SkyScene)), const Size(320, 625));
      expect(tester.takeException(), isNull);
    },
  );

  test('maps every database mood to an exported Home cloud asset', () async {
    for (final mood in Mood.values) {
      final visual = mood.visual;
      final data = await rootBundle.load(visual.assetPath);

      expect(visual.label, isNotEmpty, reason: mood.databaseValue);
      expect(data.lengthInBytes, greaterThan(0), reason: visual.assetPath);
    }
  });
}
