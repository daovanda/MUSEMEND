class TravelEnergy {
  const TravelEnergy({
    required this.currentEnergy,
    required this.journeyEnergyUsed,
    required this.journeyStatus,
  });

  final int currentEnergy;
  final int journeyEnergyUsed;
  final String journeyStatus;

  int get availableEnergy => currentEnergy - journeyEnergyUsed;
}
