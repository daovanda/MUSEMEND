import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/core/presentation/muse_ui.dart';

void main() {
  testWidgets('MuseTopBar renders shared branding and optional status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MuseTopBar(trailing: Text('Trạng thái'))),
      ),
    );

    expect(find.text('MuseMend'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    expect(find.text('Trạng thái'), findsOneWidget);
    expect(tester.getSize(find.byType(MuseTopBar)).height, 60);
  });

  test('responsive gutters preserve mobile space and cap wide content', () {
    expect(MuseResponsiveList.horizontalGutter(320), 14);
    expect(MuseResponsiveList.horizontalGutter(390), 20);
    expect(MuseResponsiveList.horizontalGutter(768), 24);
    expect(MuseResponsiveList.horizontalGutter(1200), 240);
  });

  testWidgets('tagline and responsive list fit a narrow phone viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MuseResponsiveList(
            children: [
              MuseTopBar(trailing: MusePageBadge(label: 'Khám phá')),
              MusePageTagline(
                'Biến những điều nhỏ bạn hoàn thành thành một chuyến đi dịu dàng.',
              ),
              SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );

    expect(find.text('MuseMend'), findsOneWidget);
    expect(find.text('Khám phá'), findsOneWidget);
    expect(
      find.text(
        '“Biến những điều nhỏ bạn hoàn thành thành một chuyến đi dịu dàng.”',
      ),
      findsOneWidget,
    );
    expect(find.byType(MusePageTagline), findsOneWidget);
    expect(tester.getSize(find.byType(MuseTopBar)).width, 292);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pump();

    expect(tester.getSize(find.byType(MuseTopBar)).width, 720);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared page clouds drift and honor reduce motion', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    Future<void> pumpBackground({required bool disableAnimations}) async {
      await tester.pumpWidget(
        MaterialApp(
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: disableAnimations),
                child: child!,
              ),
          home: const Scaffold(
            body: MusePageBackground(
              child: Center(child: Text('Nội dung trang')),
            ),
          ),
        ),
      );
    }

    const driftKey = ValueKey('muse-page-cloud-drift');
    await pumpBackground(disableAnimations: false);
    final movingBefore =
        tester.widget<Transform>(find.byKey(driftKey)).transform.clone();
    await tester.pump(const Duration(seconds: 2));
    final movingAfter =
        tester.widget<Transform>(find.byKey(driftKey)).transform;
    expect(movingAfter.storage, isNot(orderedEquals(movingBefore.storage)));
    for (var row = 0; row < 2; row++) {
      for (var column = 0; column < 2; column++) {
        expect(
          find.byKey(ValueKey('muse-cloud-frame-$row-$column')),
          findsOneWidget,
        );
      }
    }

    await pumpBackground(disableAnimations: true);
    final stillBefore =
        tester.widget<Transform>(find.byKey(driftKey)).transform.clone();
    await tester.pump(const Duration(seconds: 2));
    final stillAfter = tester.widget<Transform>(find.byKey(driftKey)).transform;
    expect(stillAfter.storage, orderedEquals(stillBefore.storage));
    expect(find.text('Nội dung trang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared clouds follow vertical scrolling with gentle parallax', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MusePageBackground(
            child: SingleChildScrollView(
              child: SizedBox(height: 1800, width: double.infinity),
            ),
          ),
        ),
      ),
    );

    const driftKey = ValueKey('muse-page-cloud-drift');
    final before =
        tester.widget<Transform>(find.byKey(driftKey)).transform.storage[13];
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -320),
    );
    await tester.pump();
    final after =
        tester.widget<Transform>(find.byKey(driftKey)).transform.storage[13];

    expect(after, lessThan(before));
    expect(tester.takeException(), isNull);
  });
}
