import 'package:musemend/features/journals/data/journal_entry_mapper.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_media.dart';
import 'package:musemend/features/journals/domain/journal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseJournalRepository implements JournalRepository {
  SupabaseJournalRepository(this._client);

  final SupabaseClient _client;
  static const _mapper = JournalEntryMapper();
  static const _uuid = Uuid();

  @override
  Future<List<JournalEntry>> loadEntries() async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('journals')
          .select('id, journal_type, title, updated_at')
          .inFilter('journal_type', ['daily', 'future_letter'])
          .order('updated_at', ascending: false)
          .limit(50),
      _client.from('daily_journals').select('journal_id, entry_date, content'),
      _client
          .from('future_letters')
          .select('journal_id, content, deliver_at, status, opened_at'),
      _client
          .from('journal_media')
          .select('id, journal_id, storage_path')
          .eq('media_type', 'image')
          .eq('upload_status', 'completed')
          .order('order_index', ascending: true),
    ]);
    return _mapper.fromResponses(responses);
  }

  @override
  Future<void> saveDaily({
    String? id,
    required String title,
    required String content,
  }) async {
    await _save(
      type: 'daily',
      id: id,
      data: {
        'title': _nullable(title),
        'preview_text': _preview(content),
        'content': content.trim(),
        'is_draft': false,
      },
    );
  }

  @override
  Future<void> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
  }) async {
    await _save(
      type: 'future_letter',
      id: id,
      data: {
        'title': _nullable(title),
        'preview_text': _preview(content),
        'content': content.trim(),
        'deliver_at': deliverAt.toUtc().toIso8601String(),
        'recipient_type': 'self',
      },
    );
  }

  @override
  Future<void> openFutureLetter(String id) async {
    await _client.rpc('open_future_letter', params: {'p_journal_id': id});
  }

  @override
  Future<void> attachImage(String journalId, PickedJournalImage image) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Authenticated user required.');
    final fileName = '${_uuid.v4()}.${image.extension}';
    final path = '$userId/$journalId/$fileName';
    Object? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _client.storage
            .from('journal-media')
            .uploadBinary(
              path,
              image.bytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                contentType: image.mimeType,
                upsert: false,
              ),
            );
      } catch (error) {
        lastError = error;
      }

      try {
        await _client.rpc(
          'attach_journal_media',
          params: {
            'p_journal_id': journalId,
            'p_path': path,
            'p_type': 'image',
            'p_thumbnail': null,
          },
        );
        return;
      } catch (error) {
        lastError = error;
        if (attempt < 2) {
          await Future<void>.delayed(
            Duration(milliseconds: 250 * (attempt + 1)),
          );
        }
      }
    }
    throw lastError ?? StateError('Image attachment failed.');
  }

  @override
  Future<String> createMediaUrl(String storagePath) {
    return _client.storage
        .from('journal-media')
        .createSignedUrl(storagePath, 300);
  }

  @override
  Future<void> delete(String id) async {
    await _client.rpc('soft_delete_journal', params: {'p_journal_id': id});
  }

  Future<void> _save({
    required String type,
    required String? id,
    required Map<String, dynamic> data,
  }) async {
    await _client.rpc(
      'save_journal',
      params: {'p_type': type, 'p_data': data, 'p_journal_id': id},
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _preview(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 120 ? trimmed : trimmed.substring(0, 120);
  }
}
