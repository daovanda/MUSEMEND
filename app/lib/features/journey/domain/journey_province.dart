import 'package:musemend/features/journey/domain/journey_checkpoint.dart';

class JourneyProvince {
  const JourneyProvince({
    required this.id,
    required this.name,
    required this.description,
    required this.completionPercent,
    required this.checkpoints,
    this.coverAssetPath,
    this.mapAssetPath,
  });

  final int id;
  final String name;
  final String? description;
  final int completionPercent;
  final List<JourneyCheckpoint> checkpoints;

  /// Private/local asset path for the province artwork. The path is catalog
  /// data, never a client-controlled URL.
  final String? coverAssetPath;
  final String? mapAssetPath;
}
