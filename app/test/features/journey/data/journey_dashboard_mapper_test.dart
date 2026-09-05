import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/journey/data/journey_dashboard_mapper.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';

void main() {
  const mapper = JourneyDashboardMapper();

  test('maps a journey that has not started', () {
    final dashboard = mapper.fromResponses([
      {
        'current_province_id': null,
        'current_checkpoint_id': null,
        'current_energy': 5,
        'journey_energy_used': 0,
        'journey_status': 'not_started',
      },
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
      <dynamic>[],
    ]);

    expect(dashboard.status, JourneyStatus.notStarted);
    expect(dashboard.availableEnergy, 5);
    expect(dashboard.province, isNull);
    expect(dashboard.canStart, isTrue);
  });

  test('maps checkpoint progress and unlocked collections', () {
    final dashboard = mapper.fromResponses([
      {
        'current_province_id': 1,
        'current_checkpoint_id': 10,
        'current_energy': 5,
        'journey_energy_used': 0,
        'journey_status': 'in_progress',
      },
      [
        {'id': 1, 'name': 'Hà Nội', 'description': 'Thủ đô'},
      ],
      [
        {
          'id': 11,
          'province_id': 1,
          'checkpoint_number': 2,
          'title': 'Trạm 2',
          'description': null,
          'required_energy': 10,
        },
        {
          'id': 10,
          'province_id': 1,
          'checkpoint_number': 1,
          'title': 'Trạm 1',
          'description': null,
          'required_energy': 10,
        },
      ],
      [
        {'checkpoint_id': 10, 'earned_energy': 5, 'status': 'in_progress'},
      ],
      [
        {'province_id': 1, 'completion_percent': 0},
      ],
      [
        {
          'landmark_id': 20,
          'unlocked_at': '2026-09-05T10:00:00Z',
          'is_viewed': false,
        },
      ],
      <dynamic>[],
      <dynamic>[],
      [
        {'id': 20, 'name': 'Hồ Gươm', 'description': null, 'rarity': 'common'},
      ],
      <dynamic>[],
      <dynamic>[],
    ]);

    expect(dashboard.status, JourneyStatus.inProgress);
    expect(dashboard.province?.name, 'Hà Nội');
    expect(
      dashboard.province?.checkpoints.map((checkpoint) => checkpoint.number),
      [1, 2],
    );
    expect(dashboard.province?.checkpoints.first.earnedEnergy, 5);
    expect(dashboard.province?.checkpoints.first.progress, 0.5);
    expect(dashboard.collectibles.single.kind, CollectibleKind.landmark);
    expect(dashboard.collectibles.single.name, 'Hồ Gươm');
  });
}
