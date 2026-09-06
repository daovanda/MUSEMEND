import 'package:flutter_test/flutter_test.dart';
import 'package:musemend/features/journals/data/journal_entry_mapper.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';

void main() {
  test('maps daily journals and future letters', () {
    const mapper = JournalEntryMapper();
    final entries = mapper.fromResponses([
      [
        {
          'id': 'daily-id',
          'journal_type': 'daily',
          'title': 'Hôm nay',
          'updated_at': '2026-09-05T10:00:00Z',
        },
        {
          'id': 'letter-id',
          'journal_type': 'future_letter',
          'title': 'Gửi mình',
          'updated_at': '2026-09-05T09:00:00Z',
        },
      ],
      [
        {
          'journal_id': 'daily-id',
          'entry_date': '2026-09-05',
          'content': 'Một ngày dịu dàng.',
        },
      ],
      [
        {
          'journal_id': 'letter-id',
          'content': 'Hẹn gặp lại.',
          'deliver_at': '2026-09-06T02:00:00Z',
          'status': 'scheduled',
          'opened_at': null,
        },
      ],
      [
        {
          'id': 'media-id',
          'journal_id': 'daily-id',
          'storage_path': 'user/daily-id/photo.jpg',
        },
      ],
      [
        {'id': 'tag-id', 'name': 'Bình yên'},
      ],
      [
        {'journal_id': 'daily-id', 'tag_id': 'tag-id'},
      ],
    ]);

    expect(entries.first.kind, JournalKind.daily);
    expect(entries.first.content, 'Một ngày dịu dàng.');
    expect(entries.first.media.single.id, 'media-id');
    expect(entries.first.tags.single.name, 'Bình yên');
    expect(entries.last.kind, JournalKind.futureLetter);
    expect(entries.last.status, 'scheduled');
    expect(entries.last.openedAt, isNull);
  });
}
