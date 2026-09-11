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
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  @override
  Future<List<JournalEntry>> loadEntries() async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('journals')
          .select('id, journal_type, title, created_at, updated_at')
          .inFilter('journal_type', ['daily', 'future_letter'])
          .order('updated_at', ascending: false)
          .limit(50),
      _client.from('daily_journals').select('journal_id, entry_date, content'),
      _client
          .from('future_letters')
          .select('journal_id, content, deliver_at, status, opened_at'),
      _loadMediaRows(),
      _client
          .from('journal_tags')
          .select('id, name')
          .order('name', ascending: true),
      _client.from('journal_tag_assignments').select('journal_id, tag_id'),
    ]);
    return _mapper.fromResponses(responses);
  }

  @override
  Future<List<JournalEntry>> loadDailyJournals({
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('journals')
          .select('id, journal_type, title, created_at, updated_at')
          .eq('journal_type', 'daily'),
      _client
          .from('daily_journals')
          .select('journal_id, entry_date, content')
          .gte('entry_date', _dateString(from))
          .lt('entry_date', _dateString(toExclusive)),
    ]);
    final journals = (responses[0] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
    final dailyById = {
      for (final row in (responses[1] as List).map(
        (row) => Map<String, dynamic>.from(row as Map),
      ))
        row['journal_id'] as String: row,
    };
    return journals
        .map((journal) {
          final id = journal['id'] as String;
          final detail = dailyById[id];
          if (detail == null) return null;
          return JournalEntry(
            id: id,
            kind: JournalKind.daily,
            title: journal['title'] as String?,
            content: detail['content'] as String,
            createdAt: DateTime.parse(journal['created_at'] as String),
            updatedAt: DateTime.parse(journal['updated_at'] as String),
            entryDate: DateTime.parse(detail['entry_date'] as String),
          );
        })
        .whereType<JournalEntry>()
        .toList(growable: false);
  }

  @override
  Future<JournalEntry?> loadEntry(String id) async {
    if (!_uuidPattern.hasMatch(id)) return null;
    final responses = await Future.wait<dynamic>([
      _client
          .from('journals')
          .select('id, journal_type, title, created_at, updated_at')
          .eq('id', id)
          .inFilter('journal_type', ['daily', 'future_letter'])
          .limit(1),
      _client
          .from('daily_journals')
          .select('journal_id, entry_date, content')
          .eq('journal_id', id),
      _client
          .from('future_letters')
          .select('journal_id, content, deliver_at, status, opened_at')
          .eq('journal_id', id),
      _loadMediaRows(journalId: id),
      _client.from('journal_tags').select('id, name').order('name'),
      _client
          .from('journal_tag_assignments')
          .select('journal_id, tag_id')
          .eq('journal_id', id),
    ]);
    final entries = _mapper.fromResponses(responses);
    return entries.isEmpty ? null : entries.single;
  }

  @override
  Future<String> saveDaily({
    String? id,
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    return _save(
      type: 'daily',
      id: id,
      data: {
        'title': _nullable(title),
        'preview_text': _preview(content),
        'content': content.trim(),
        'is_draft': false,
      },
      tags: tags,
    );
  }

  @override
  Future<String> saveFutureLetter({
    String? id,
    required String title,
    required String content,
    required DateTime deliverAt,
    required List<String> tags,
  }) async {
    return _save(
      type: 'future_letter',
      id: id,
      data: {
        'title': _nullable(title),
        'preview_text': _preview(content),
        'content': content.trim(),
        'deliver_at': deliverAt.toUtc().toIso8601String(),
        'recipient_type': 'self',
      },
      tags: tags,
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
  Future<void> updateMediaTransform(JournalMedia media) async {
    await _client.rpc(
      'update_journal_media_transform',
      params: {
        'p_media_id': media.id,
        'p_position_x': media.offsetX,
        'p_position_y': media.offsetY,
        'p_display_scale': media.scale,
        'p_rotation_radians': media.rotation,
      },
    );
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

  Future<String> _save({
    required String type,
    required String? id,
    required Map<String, dynamic> data,
    required List<String> tags,
  }) async {
    final result = await _client.rpc(
      'save_journal_with_tags',
      params: {
        'p_type': type,
        'p_data': data,
        'p_names': tags,
        'p_journal_id': id,
      },
    );
    if (result is! String) {
      throw const FormatException('save_journal returned an invalid id.');
    }
    return result;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _preview(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 120 ? trimmed : trimmed.substring(0, 120);
  }

  String _dateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// Reads transform metadata when the migration is present, while keeping
  /// journal reads usable during a staged rollout before that migration lands
  /// on the remote project. The transform RPC remains the source of truth for
  /// writes and will fail safely until the migration is deployed.
  Future<List<dynamic>> _loadMediaRows({String? journalId}) async {
    try {
      if (journalId == null) {
        return await _client
            .from('journal_media')
            .select(
              'id, journal_id, storage_path, position_x, position_y, display_scale, rotation_radians',
            )
            .eq('media_type', 'image')
            .eq('upload_status', 'completed')
            .order('order_index', ascending: true);
      }
      return await _client
          .from('journal_media')
          .select(
            'id, journal_id, storage_path, position_x, position_y, display_scale, rotation_radians',
          )
          .eq('journal_id', journalId)
          .eq('media_type', 'image')
          .eq('upload_status', 'completed')
          .order('order_index', ascending: true);
    } catch (error) {
      if (!_isMissingTransformColumns(error)) rethrow;

      if (journalId == null) {
        return await _client
            .from('journal_media')
            .select('id, journal_id, storage_path')
            .eq('media_type', 'image')
            .eq('upload_status', 'completed')
            .order('order_index', ascending: true);
      }
      return await _client
          .from('journal_media')
          .select('id, journal_id, storage_path')
          .eq('journal_id', journalId)
          .eq('media_type', 'image')
          .eq('upload_status', 'completed')
          .order('order_index', ascending: true);
    }
  }

  bool _isMissingTransformColumns(Object error) {
    if (error is! PostgrestException) return false;
    final message = error.message.toLowerCase();
    return error.code == '42703' ||
        message.contains('position_x') ||
        message.contains('position_y') ||
        message.contains('display_scale') ||
        message.contains('rotation_radians');
  }
}
