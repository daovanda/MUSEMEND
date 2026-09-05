import 'package:musemend/features/journey/domain/journey_checkpoint.dart';

class JourneyProvince {
  const JourneyProvince({
    required this.id,
    required this.name,
    required this.description,
    required this.completionPercent,
    required this.checkpoints,
  });

  final int id;
  final String name;
  final String? description;
  final int completionPercent;
  final List<JourneyCheckpoint> checkpoints;
}
