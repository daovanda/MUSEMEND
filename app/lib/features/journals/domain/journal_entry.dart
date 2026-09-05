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
}
