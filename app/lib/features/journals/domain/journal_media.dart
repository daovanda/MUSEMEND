import 'dart:typed_data';

class JournalMedia {
  const JournalMedia({required this.id, required this.storagePath});

  final String id;
  final String storagePath;
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
