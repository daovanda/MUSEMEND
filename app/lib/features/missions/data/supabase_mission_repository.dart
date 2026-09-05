import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/missions/data/mission_dto.dart';
import 'package:musemend/features/missions/data/mission_template_dto.dart';
import 'package:musemend/features/missions/domain/mission_completion.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_repository.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/travel_energy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseMissionRepository implements MissionRepository {
  SupabaseMissionRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  @override
  Future<MissionDashboard> loadDashboard({required Mood? todayMood}) async {
    final results = await Future.wait<dynamic>([
      _client
          .from('user_missions')
          .select(
            'id, template_id, title_snapshot, description_snapshot, '
            'energy_reward, status, source_type, due_at',
          )
          .inFilter('status', ['pending', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(20),
      _client
          .from('mission_templates')
          .select(
            'id, title, description, target_mood, default_energy_reward, '
            'estimated_minutes',
          )
          .eq('is_active', true)
          .order('id'),
      _client
          .from('travel_progress')
          .select('current_energy, journey_energy_used, journey_status')
          .single(),
    ]);

    final missions = _mapRows(
      results[0],
      MissionDto.fromMap,
    ).map((dto) => dto.toDomain()).toList(growable: false);
    final activeTemplateIds =
        missions.map((mission) => mission.templateId).whereType<int>().toSet();
    final templates = _mapRows(results[1], MissionTemplateDto.fromMap)
        .map((dto) => dto.toDomain())
        .where(
          (template) =>
              !activeTemplateIds.contains(template.id) &&
              (template.targetMood == 'all' ||
                  template.targetMood == todayMood?.databaseValue),
        )
        .toList(growable: false);
    final progress = Map<String, dynamic>.from(results[2] as Map);

    return MissionDashboard(
      missions: missions,
      suggestions: templates,
      energy: TravelEnergy(
        currentEnergy: (progress['current_energy'] as num).toInt(),
        journeyEnergyUsed: (progress['journey_energy_used'] as num).toInt(),
        journeyStatus: progress['journey_status'] as String,
      ),
    );
  }

  @override
  Future<void> addTemplate({
    required MissionTemplate template,
    required String? todayCheckinId,
  }) async {
    if (template.requiresMood && todayCheckinId == null) {
      throw StateError('A mood check-in is required for this template.');
    }
    await _client.rpc(
      'create_mission',
      params: {
        'p_template_id': template.id,
        'p_title': null,
        'p_description': null,
        'p_checkin_id': template.requiresMood ? todayCheckinId : null,
        'p_request_id': null,
      },
    );
  }

  @override
  Future<void> createCustom({
    required String title,
    required String? description,
  }) async {
    await _client.rpc(
      'create_mission',
      params: {
        'p_template_id': null,
        'p_title': title.trim(),
        'p_description': _nullableTrim(description),
        'p_checkin_id': null,
        'p_request_id': _uuid.v4(),
      },
    );
  }

  @override
  Future<MissionCompletion> complete(String missionId) async {
    final result = await _client.rpc(
      'complete_mission',
      params: {'p_mission_id': missionId},
    );
    final row = _singleObject(result, 'complete_mission');
    return MissionCompletion(
      reward: (row['reward'] as num).toInt(),
      alreadyCompleted: row['already_completed'] as bool,
    );
  }

  @override
  Future<void> skip(String missionId) async {
    await _client.rpc('skip_mission', params: {'p_mission_id': missionId});
  }

  List<T> _mapRows<T>(Object? value, T Function(Map<String, dynamic>) map) {
    if (value is! List) {
      throw const FormatException('Expected a list response.');
    }
    return value
        .map((row) => map(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Map<String, dynamic> _singleObject(Object? value, String operation) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.length == 1 && value.single is Map) {
      return Map<String, dynamic>.from(value.single as Map);
    }
    throw FormatException('$operation returned an unexpected response.');
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
