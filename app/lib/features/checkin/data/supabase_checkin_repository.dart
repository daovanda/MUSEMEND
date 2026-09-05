import 'package:musemend/features/checkin/domain/app_visit.dart';
import 'package:musemend/features/checkin/domain/checkin_repository.dart';
import 'package:musemend/features/checkin/domain/daily_checkin.dart';
import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCheckinRepository implements CheckinRepository {
  SupabaseCheckinRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<DailyCheckin?> loadToday() async {
    final row =
        await _client
            .from('daily_checkins')
            .select('id, checkin_date, mood, energy_level, note')
            .eq('checkin_date', _vietnamDateString())
            .maybeSingle();
    return row == null ? null : _mapCheckin(row);
  }

  @override
  Future<AppVisit> recordAppOpen() async {
    final result = await _client.rpc('record_app_open');
    final row = _singleObject(result, 'record_app_open');
    return AppVisit(
      visitDate: DateTime.parse(row['visit_date'] as String),
      streak: (row['streak'] as num).toInt(),
    );
  }

  @override
  Future<DailyCheckin> saveToday({
    required Mood mood,
    required int? energyLevel,
    required String? note,
  }) async {
    final result = await _client.rpc(
      'upsert_daily_checkin',
      params: {
        'p_mood': mood.databaseValue,
        'p_energy_level': energyLevel,
        'p_note': _nullableTrim(note),
      },
    );
    return _mapCheckin(_singleObject(result, 'upsert_daily_checkin'));
  }

  DailyCheckin _mapCheckin(Map<String, dynamic> row) {
    return DailyCheckin(
      id: row['id'] as String,
      checkinDate: DateTime.parse(row['checkin_date'] as String),
      mood: Mood.fromDatabase(row['mood'] as String),
      energyLevel: (row['energy_level'] as num?)?.toInt(),
      note: row['note'] as String?,
    );
  }

  Map<String, dynamic> _singleObject(Object? value, String operation) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.length == 1 && value.single is Map) {
      return Map<String, dynamic>.from(value.single as Map);
    }
    throw FormatException('$operation returned an unexpected response.');
  }

  String _vietnamDateString() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
