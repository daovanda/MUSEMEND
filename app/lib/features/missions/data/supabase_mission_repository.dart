import 'package:musemend/features/checkin/domain/mood.dart';
import 'package:musemend/features/missions/data/mission_dto.dart';
import 'package:musemend/features/missions/data/mission_template_dto.dart';
import 'package:musemend/features/missions/domain/mission_completion.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_repository.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/mission_type.dart';
import 'package:musemend/features/missions/domain/travel_energy.dart';
import 'package:musemend/features/missions/domain/user_mission.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseMissionRepository implements MissionRepository {
  SupabaseMissionRepository(this._client);

  final SupabaseClient _client;
  static const _uuid = Uuid();

  @override
  Future<MissionDashboard> loadDashboard({
    required Mood? todayMood,
    required String languageCode,
  }) async {
    await _refreshScheduledMissions();
    // Starter missions are materialized by an idempotent server command. This
    // keeps the Home screen useful for a new account while preserving server
    // ownership of rewards, snapshots and daily occurrence keys.
    await _ensureHomeMissions();
    final now = DateTime.now().toUtc().toIso8601String();
    final todayKey = _vietnamDateKey();
    final results = await Future.wait<dynamic>([
      _client
          .from('user_missions')
          .select(
            'id, template_id, title_snapshot, description_snapshot, '
            'energy_reward, status, source_type, mission_type, start_at, due_at',
          )
          .inFilter('status', ['pending', 'in_progress'])
          // A daily mission remains pending when it is not completed. It is
          // still valid in the database for audit/history, but must not keep
          // appearing on Home after its due time.
          .or('due_at.is.null,due_at.gte.$now')
          .order('created_at', ascending: false)
          .limit(20),
      _client
          .from('user_missions')
          .select('template_id, occurrence_key, recurrence_series_id, due_at')
          .not('template_id', 'is', null)
          .order('created_at', ascending: false)
          .limit(500),
      _client
          .from('mission_templates')
          .select(
            'id, title, description, target_mood, default_energy_reward, '
            'estimated_minutes, mission_type, '
            'mission_template_translations(language_code, title, description)',
          )
          .eq('is_active', true)
          .order('id', ascending: true),
      _client
          .from('travel_progress')
          .select('current_energy, journey_energy_used, journey_status')
          .single(),
    ]);

    final snapshotMissions = _deduplicateActiveSystemMissions(
      _mapRows(results[0], MissionDto.fromMap).map((dto) => dto.toDomain()),
    );
    final usedTemplateIds =
        _mapRows<Map<String, dynamic>>(results[1], (row) => row)
            .where((row) {
              if (row['recurrence_series_id'] != null) return true;
              final due = row['due_at'] as String?;
              if (due != null &&
                  !DateTime.parse(due).isBefore(DateTime.now().toUtc())) {
                return true;
              }
              return (row['occurrence_key'] as String?)?.endsWith(
                    ':$todayKey',
                  ) ??
                  false;
            })
            .map((row) => (row['template_id'] as num).toInt())
            .toSet();
    final localizedTemplates = _mapRows(
      results[2],
      (row) => MissionTemplateDto.fromMap(row, languageCode: languageCode),
    ).map((dto) => dto.toDomain()).toList(growable: false);
    final localizedTemplatesById = {
      for (final template in localizedTemplates) template.id: template,
    };
    final missions = snapshotMissions
        .map((mission) {
          final template =
              mission.templateId == null
                  ? null
                  : localizedTemplatesById[mission.templateId];
          if (template == null) return mission;
          return UserMission(
            id: mission.id,
            templateId: mission.templateId,
            title: template.title,
            description: template.description,
            energyReward: mission.energyReward,
            status: mission.status,
            sourceType: mission.sourceType,
            missionType: mission.missionType,
            startAt: mission.startAt,
            dueAt: mission.dueAt,
          );
        })
        .toList(growable: false);
    final activeTemplateIds =
        missions.map((mission) => mission.templateId).whereType<int>().toSet();
    final templates = localizedTemplates
        .where(
          (template) =>
              !activeTemplateIds.contains(template.id) &&
              !usedTemplateIds.contains(template.id) &&
              (template.targetMood == 'all' ||
                  template.targetMood == todayMood?.databaseValue),
        )
        .toList(growable: false);
    final progress = Map<String, dynamic>.from(results[3] as Map);

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
    required DateTime? startAt,
    required DateTime? dueAt,
  }) async {
    if (template.requiresMood && todayCheckinId == null) {
      throw StateError('A mood check-in is required for this template.');
    }
    await _client.rpc(
      'create_scheduled_mission',
      params: {
        'p_mission_type': template.missionType.databaseValue,
        'p_template_id': template.id,
        'p_title': null,
        'p_description': null,
        'p_start_at': startAt?.toUtc().toIso8601String(),
        'p_due_at': dueAt?.toUtc().toIso8601String(),
        'p_checkin_id': template.requiresMood ? todayCheckinId : null,
        'p_request_id': _uuid.v4(),
      },
    );
  }

  @override
  Future<void> createScheduled({
    required MissionType missionType,
    required String title,
    required String? description,
    required DateTime? startAt,
    required DateTime? dueAt,
  }) async {
    await _client.rpc(
      'create_scheduled_mission',
      params: {
        'p_mission_type': missionType.databaseValue,
        'p_template_id': null,
        'p_title': title.trim(),
        'p_description': _nullableTrim(description),
        'p_start_at': startAt?.toUtc().toIso8601String(),
        'p_due_at': dueAt?.toUtc().toIso8601String(),
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

  String _vietnamDateKey() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  List<UserMission> _deduplicateActiveSystemMissions(
    Iterable<UserMission> missions,
  ) {
    final seenTemplates = <int>{};
    final visible = <UserMission>[];
    for (final mission in missions) {
      final templateId = mission.templateId;
      if (mission.sourceType == 'system' &&
          templateId != null &&
          !seenTemplates.add(templateId)) {
        // Older development data can contain a second snapshot created before
        // occurrence_key was introduced. The newest row wins because the
        // query is ordered by created_at descending; custom missions are never
        // deduplicated because users may intentionally reuse a title.
        continue;
      }
      visible.add(mission);
    }
    return List.unmodifiable(visible);
  }

  Future<void> _ensureHomeMissions() async {
    try {
      await _client.rpc('ensure_home_missions');
    } on PostgrestException catch (error) {
      // Keep an older development schema readable while the migration is being
      // deployed. All other errors remain visible to the retry state.
      if (error.code == 'PGRST202') return;
      rethrow;
    }
  }

  Future<void> _refreshScheduledMissions() async {
    try {
      await _client.rpc('refresh_scheduled_missions');
    } on PostgrestException catch (error) {
      // Backward-compatible while the new migration is rolling out to Dev.
      if (error.code == 'PGRST202') return;
      rethrow;
    }
  }
}
