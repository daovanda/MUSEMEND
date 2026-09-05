import 'package:musemend/features/journals/data/journal_entry_mapper.dart';
import 'package:musemend/features/journals/domain/journal_entry.dart';
import 'package:musemend/features/journals/domain/journal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseJournalRepository implements JournalRepository {
  SupabaseJournalRepository(this._client);

  final SupabaseClient _client;
  static const _mapper = JournalEntryMapper();

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
