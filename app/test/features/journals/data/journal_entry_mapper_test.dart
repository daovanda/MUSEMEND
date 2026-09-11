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
          'created_at': '2026-09-04T10:00:00Z',
          'updated_at': '2026-09-05T10:00:00Z',
        },
        {
          'id': 'letter-id',
          'journal_type': 'future_letter',
          'title': 'Gửi mình',
          'created_at': '2026-09-04T09:00:00Z',
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
          'position_x': 0.2,
          'position_y': -0.1,
          'display_scale': 1.75,
          'rotation_radians': 1.2,
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
    expect(entries.first.createdAt, DateTime.parse('2026-09-04T10:00:00Z'));
    expect(entries.first.content, 'Một ngày dịu dàng.');
    expect(entries.first.media.single.id, 'media-id');
    expect(entries.first.media.single.offsetX, 0.2);
    expect(entries.first.media.single.offsetY, -0.1);
    expect(entries.first.media.single.scale, 1.75);
    expect(entries.first.media.single.rotation, 1.2);
    expect(entries.first.tags.single.name, 'Bình yên');
    expect(entries.last.kind, JournalKind.futureLetter);
    expect(entries.last.createdAt, DateTime.parse('2026-09-04T09:00:00Z'));
    expect(entries.last.status, 'scheduled');
    expect(entries.last.openedAt, isNull);
  });

  test('keeps legacy media rows at the default transform', () {
    const mapper = JournalEntryMapper();
    final entries = mapper.fromResponses([
      [
        {
          'id': 'daily-id',
          'journal_type': 'daily',
          'title': null,
          'updated_at': '2026-09-05T10:00:00Z',
        },
      ],
      [
        {
          'journal_id': 'daily-id',
          'entry_date': '2026-09-05',
          'content': 'Nội dung',
        },
      ],
      const [],
      [
        {
          'id': 'media-id',
          'journal_id': 'daily-id',
          'storage_path': 'user/daily-id/photo.jpg',
        },
      ],
      const [],
      const [],
    ]);

    final media = entries.single.media.single;
    expect(media.offsetX, 0);
    expect(media.offsetY, 0);
    expect(media.scale, 1);
    expect(media.rotation, 0);
  });
}
