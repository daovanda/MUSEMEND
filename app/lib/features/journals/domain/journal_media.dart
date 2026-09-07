import 'dart:typed_data';

class JournalMedia {
  const JournalMedia({
    required this.id,
    required this.storagePath,
    this.offsetX = 0,
    this.offsetY = 0,
    this.scale = 1,
    this.rotation = 0,
  });

  final String id;
  final String storagePath;

  /// Normalized offset from the center of the editor canvas.
  final double offsetX;
  final double offsetY;

  /// Uniform visual scale. The original image aspect ratio is always kept.
  final double scale;

  /// Rotation in radians, as produced by Flutter's scale gesture recognizer.
  final double rotation;

  JournalMedia copyWith({
    double? offsetX,
    double? offsetY,
    double? scale,
    double? rotation,
  }) {
    return JournalMedia(
      id: id,
      storagePath: storagePath,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

class PickedJournalImage {
  const PickedJournalImage({
    required this.bytes,
    required this.extension,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String extension;
  final String mimeType;
}

enum JournalImageResult { success, canceled, tooLarge, unsupported, failed }
