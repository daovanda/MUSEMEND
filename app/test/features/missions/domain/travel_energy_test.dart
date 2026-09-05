import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/missions/domain/travel_energy.dart';

void main() {
  test('available energy subtracts only energy allocated to journey', () {
    const energy = TravelEnergy(
      currentEnergy: 15,
      journeyEnergyUsed: 10,
      journeyStatus: 'in_progress',
    );

    expect(energy.availableEnergy, 5);
    expect(energy.currentEnergy, 15);
  });
}
