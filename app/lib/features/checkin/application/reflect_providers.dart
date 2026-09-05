import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/checkin/application/reflect_state.dart';
import 'package:musemend/features/checkin/data/supabase_checkin_repository.dart';
import 'package:musemend/features/checkin/domain/checkin_repository.dart';
import 'package:musemend/features/checkin/domain/mood.dart';

final checkinRepositoryProvider = Provider<CheckinRepository>((ref) {
  return SupabaseCheckinRepository(ref.watch(supabaseClientProvider));
});

final reflectControllerProvider =
    AsyncNotifierProvider<ReflectController, ReflectState>(
      ReflectController.new,
    );

class ReflectController extends AsyncNotifier<ReflectState> {
  CheckinRepository get _repository => ref.read(checkinRepositoryProvider);

  @override
  Future<ReflectState> build() async {
    final visit = await _repository.recordAppOpen();
    final checkin = await _repository.loadToday();
    return ReflectState(streak: visit.streak, today: checkin);
  }

  Future<void> recordAppOpen() async {
    final current = state.value;
    if (current == null) return;
    try {
      final visit = await _repository.recordAppOpen();
      state = AsyncData(current.copyWith(streak: visit.streak));
    } catch (_) {
      // A foreground refresh must not replace usable content with a transient error.
    }
  }

  Future<bool> save({
    required Mood mood,
    required int? energyLevel,
    required String? note,
  }) async {
    final current = state.value;
    if (current == null) return false;
    state = const AsyncLoading();
    try {
      final checkin = await _repository.saveToday(
        mood: mood,
        energyLevel: energyLevel,
        note: note,
      );
      state = AsyncData(current.copyWith(today: checkin));
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
