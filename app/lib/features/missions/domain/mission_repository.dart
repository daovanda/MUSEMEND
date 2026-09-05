import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/missions/domain/mission_completion.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';

abstract interface class MissionRepository {
  Future<MissionDashboard> loadDashboard({required Mood? todayMood});

  Future<void> addTemplate({
    required MissionTemplate template,
    required String? todayCheckinId,
  });

  Future<void> createCustom({
    required String title,
    required String? description,
  });

  Future<MissionCompletion> complete(String missionId);

  Future<void> skip(String missionId);
}
