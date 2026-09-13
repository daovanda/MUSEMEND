import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_destination.dart';
import 'package:musemend/features/journey/domain/journey_repository.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';
import 'package:musemend/features/library/presentation/library_screen.dart';
import 'package:musemend/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows destination details and filters the collection', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journeyRepositoryProvider.overrideWithValue(_FakeJourneyRepository()),
        ],
        child: MaterialApp(
          locale: const Locale('vi'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder:
              (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          home: const Scaffold(body: LibraryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ninh Bình'), findsOneWidget);
    expect(
      find.text('Thở cùng núi đá vôi và dòng sông trong.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Nhịp chèo Tràng An'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Nhịp chèo Tràng An'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Món ăn · 1'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Tràng An'), findsOneWidget);
    expect(find.text('Cơm cháy'), findsOneWidget);

    await tester.tap(find.text('Món ăn · 1'));
    await tester.pumpAndSettle();

    expect(find.text('Cơm cháy'), findsOneWidget);
    expect(find.text('Tràng An'), findsNothing);
  });
}

class _FakeJourneyRepository implements JourneyRepository {
  @override
  Future<JourneyDashboard> loadDashboard({
    required String languageCode,
  }) async => JourneyDashboard(
    status: JourneyStatus.inProgress,
    currentEnergy: 8,
    journeyEnergyUsed: 3,
    currentCheckpointId: 10,
    destination: const JourneyDestination(
      id: 1,
      name: 'Ninh Bình',
      description: 'Thở cùng núi đá vôi và dòng sông trong.',
      countryCode: 'VN',
      destinationType: 'province',
      completionPercent: 40,
      checkpoints: [
        JourneyCheckpoint(
          id: 10,
          number: 1,
          title: 'Nhịp chèo Tràng An',
          description: 'Đi chậm giữa sông và núi.',
          requiredEnergy: 10,
          earnedEnergy: 4,
          status: 'in_progress',
        ),
      ],
    ),
    collectibles: [
      LibraryCollectible(
        id: 20,
        kind: CollectibleKind.landmark,
        name: 'Tràng An',
        description: 'Di sản giữa núi đá vôi.',
        rarity: 'rare',
        unlockedAt: DateTime(2026, 9, 1),
        isViewed: true,
      ),
      LibraryCollectible(
        id: 21,
        kind: CollectibleKind.food,
        name: 'Cơm cháy',
        description: 'Món ăn vàng giòn.',
        rarity: 'common',
        unlockedAt: DateTime(2026, 9, 2),
        isViewed: true,
      ),
    ],
  );

  @override
  Future<void> advanceJourney() async {}

  @override
  Future<void> startJourney() async {}
}
