import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/travel_energy.dart';
import 'package:musemend/features/missions/domain/user_mission.dart';

class MissionDashboard {
  const MissionDashboard({
    required this.missions,
    required this.suggestions,
    required this.energy,
  });

  final List<UserMission> missions;
  final List<MissionTemplate> suggestions;
  final TravelEnergy energy;
}
