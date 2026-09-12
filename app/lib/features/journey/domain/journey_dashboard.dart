import 'package:musemend/features/journey/domain/journey_destination.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';

class JourneyDashboard {
  const JourneyDashboard({
    required this.status,
    required this.currentEnergy,
    required this.journeyEnergyUsed,
    required this.destination,
    required this.currentCheckpointId,
    required this.collectibles,
  });

  final JourneyStatus status;
  final int currentEnergy;
  final int journeyEnergyUsed;
  final JourneyDestination? destination;
  final int? currentCheckpointId;
  final List<LibraryCollectible> collectibles;

  int get availableEnergy => currentEnergy - journeyEnergyUsed;
  bool get canStart =>
      status == JourneyStatus.notStarted || status == JourneyStatus.paused;
}
