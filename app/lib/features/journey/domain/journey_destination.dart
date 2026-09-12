import 'package:musemend/features/journey/domain/journey_checkpoint.dart';

class JourneyDestination {
  const JourneyDestination({
    required this.id,
    required this.name,
    required this.description,
    required this.countryCode,
    required this.destinationType,
    required this.completionPercent,
    required this.checkpoints,
    this.coverAssetPath,
    this.mapAssetPath,
  });

  final int id;
  final String name;
  final String? description;
  final String? countryCode;
  final String destinationType;
  final int completionPercent;
  final List<JourneyCheckpoint> checkpoints;

  /// Server-owned catalog artwork. Local bundled assets and approved HTTPS
  /// URLs are resolved by CatalogArtwork; user-provided paths are rejected.
  final String? coverAssetPath;
  final String? mapAssetPath;

  String? get heroAssetPath {
    if (coverAssetPath != null && coverAssetPath!.isNotEmpty) {
      return coverAssetPath;
    }
    for (final checkpoint in checkpoints) {
      if (checkpoint.isCurrent && checkpoint.assetPath != null) {
        return checkpoint.assetPath;
      }
    }
    for (final checkpoint in checkpoints) {
      if (checkpoint.assetPath != null) return checkpoint.assetPath;
    }
    return null;
  }
}
