import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/missions/data/supabase_mission_repository.dart';
import 'package:musemend/features/missions/domain/mission_completion.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_repository.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return SupabaseMissionRepository(ref.watch(supabaseClientProvider));
});

final missionsControllerProvider =
    AsyncNotifierProvider<MissionsController, MissionDashboard>(
      MissionsController.new,
    );

class MissionsController extends AsyncNotifier<MissionDashboard> {
  MissionRepository get _repository => ref.read(missionRepositoryProvider);

  @override
  Future<MissionDashboard> build() async {
    final reflect = await ref.watch(reflectControllerProvider.future);
    return _repository.loadDashboard(todayMood: reflect.today?.mood);
  }

  Future<bool> addTemplate(MissionTemplate template) async {
    return _mutate((reflect) async {
      await _repository.addTemplate(
        template: template,
        todayCheckinId: reflect.today?.id,
      );
    });
  }

  Future<bool> createCustom({
    required String title,
    required String? description,
  }) {
    return _mutate(
      (_) => _repository.createCustom(title: title, description: description),
    );
  }

  Future<MissionCompletion?> complete(String missionId) async {
    MissionCompletion? completion;
    final succeeded = await _mutate((_) async {
      completion = await _repository.complete(missionId);
    });
    if (succeeded) ref.invalidate(journeyControllerProvider);
    return succeeded ? completion : null;
  }

  Future<bool> skip(String missionId) {
    return _mutate((_) => _repository.skip(missionId));
  }

  Future<bool> _mutate(
    Future<void> Function(ReflectState reflect) operation,
  ) async {
    final reflect = ref.read(reflectControllerProvider).value;
    if (reflect == null) return false;
    state = const AsyncLoading();
    try {
      await operation(reflect);
      state = AsyncData(
        await _repository.loadDashboard(todayMood: reflect.today?.mood),
      );
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
