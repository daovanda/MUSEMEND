import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/journals/domain/journal_tag.dart';

enum JournalKind { daily, futureLetter }

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.content,
    required this.updatedAt,
    this.entryDate,
    this.deliverAt,
    this.status,
    this.openedAt,
    this.media = const [],
    this.tags = const [],
  });

  final String id;
  final JournalKind kind;
  final String? title;
  final String content;
  final DateTime updatedAt;
  final DateTime? entryDate;
  final DateTime? deliverAt;
  final String? status;
  final DateTime? openedAt;
  final List<JournalMedia> media;
  final List<JournalTag> tags;
}
