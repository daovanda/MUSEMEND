import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/localization/supported_locales.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/checkin/application/reflect_providers.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/journey/application/journey_providers.dart';
import 'package:musemend/features/missions/data/supabase_mission_repository.dart';
import 'package:musemend/features/missions/domain/mission_completion.dart';
import 'package:musemend/features/missions/domain/mission_dashboard.dart';
import 'package:musemend/features/missions/domain/mission_repository.dart';
import 'package:musemend/features/missions/domain/mission_template.dart';
import 'package:musemend/features/missions/domain/mission_type.dart';
import 'package:musemend/features/profile/application/profile_providers.dart';

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
    ref.watch(appLanguageCodeProvider);
    return _repository.loadDashboard(
      todayMood: reflect.today?.mood,
      languageCode: _languageCode,
    );
  }

  Future<bool> addTemplate(
    MissionTemplate template, {
    required DateTime? startAt,
    required DateTime? dueAt,
  }) async {
    return _mutate((reflect) async {
      await _repository.addTemplate(
        template: template,
        todayCheckinId: reflect.today?.id,
        startAt: startAt,
        dueAt: dueAt,
      );
    });
  }

  Future<bool> createScheduled({
    required MissionType missionType,
    required String title,
    required String? description,
    required DateTime? startAt,
    required DateTime? dueAt,
  }) {
    return _mutate(
      (_) => _repository.createScheduled(
        missionType: missionType,
        title: title,
        description: description,
        startAt: startAt,
        dueAt: dueAt,
      ),
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
    state = const AsyncLoading();
    try {
      // The Home screen can still be hydrating the shared check-in provider
      // when a suggestion is tapped. Await it instead of treating a temporary
      // AsyncLoading state as a failed mutation.
      final reflect = await ref.read(reflectControllerProvider.future);
      await operation(reflect);
      state = AsyncData(
        await _repository.loadDashboard(
          todayMood: reflect.today?.mood,
          languageCode: _languageCode,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  String get _languageCode {
    final stored = ref.read(appLanguageCodeProvider).value;
    return resolveSupportedLanguageCode(
      stored ??
          resolveDeviceLocale(PlatformDispatcher.instance.locales).languageCode,
    );
  }
}
