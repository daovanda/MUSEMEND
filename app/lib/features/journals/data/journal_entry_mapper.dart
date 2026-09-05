import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';

class JournalEntryMapper {
  const JournalEntryMapper();

  List<JournalEntry> fromResponses(List<dynamic> responses) {
    if (responses.length != 4) {
      throw const FormatException('Incomplete journal response.');
    }
    final journals = _rows(responses[0]);
    final daily = {
      for (final row in _rows(responses[1])) row['journal_id'] as String: row,
    };
    final letters = {
      for (final row in _rows(responses[2])) row['journal_id'] as String: row,
    };
    final mediaByJournal = <String, List<JournalMedia>>{};
    for (final row in _rows(responses[3])) {
      final journalId = row['journal_id'] as String;
      mediaByJournal
          .putIfAbsent(journalId, () => [])
          .add(
            JournalMedia(
              id: row['id'] as String,
              storagePath: row['storage_path'] as String,
            ),
          );
    }

    return journals
        .map((journal) {
          final id = journal['id'] as String;
          final type = journal['journal_type'] as String;
          if (type == 'daily') {
            final detail = daily[id];
            if (detail == null) {
              throw FormatException('Daily journal $id has no detail.');
            }
            return JournalEntry(
              id: id,
              kind: JournalKind.daily,
              title: journal['title'] as String?,
              content: detail['content'] as String,
              updatedAt: DateTime.parse(journal['updated_at'] as String),
              entryDate: DateTime.parse(detail['entry_date'] as String),
              media: List.unmodifiable(mediaByJournal[id] ?? const []),
            );
          }
          if (type == 'future_letter') {
            final detail = letters[id];
            if (detail == null) {
              throw FormatException('Future letter $id has no detail.');
            }
            return JournalEntry(
              id: id,
              kind: JournalKind.futureLetter,
              title: journal['title'] as String?,
              content: detail['content'] as String,
              updatedAt: DateTime.parse(journal['updated_at'] as String),
              deliverAt: DateTime.parse(detail['deliver_at'] as String),
              status: detail['status'] as String,
              openedAt: _date(detail['opened_at']),
              media: List.unmodifiable(mediaByJournal[id] ?? const []),
            );
          }
          throw FormatException('Unsupported journal type: $type');
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is! List) throw const FormatException('Expected journal rows.');
    return value
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
