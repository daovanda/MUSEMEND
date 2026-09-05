import 'package:image_picker/image_picker.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';

class JournalImagePicker {
  JournalImagePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<(JournalImageResult, PickedJournalImage?)> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2048,
    );
    if (file == null) return (JournalImageResult.canceled, null);
    final extension = _extension(file.name);
    final mimeType = _mime(extension);
    if (mimeType == null) return (JournalImageResult.unsupported, null);
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      return (JournalImageResult.tooLarge, null);
    }
    return (
      JournalImageResult.success,
      PickedJournalImage(
        bytes: bytes,
        extension: extension,
        mimeType: mimeType,
      ),
    );
  }

  String _extension(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  String? _mime(String extension) => switch (extension) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    _ => null,
  };
}
