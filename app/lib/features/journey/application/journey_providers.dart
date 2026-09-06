import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musemend/core/supabase/supabase_client_provider.dart';
import 'package:musemend/features/journey/data/supabase_journey_repository.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_repository.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return SupabaseJourneyRepository(ref.watch(supabaseClientProvider));
});

final journeyControllerProvider =
    AsyncNotifierProvider<JourneyController, JourneyDashboard>(
      JourneyController.new,
    );

class JourneyController extends AsyncNotifier<JourneyDashboard> {
  JourneyRepository get _repository => ref.read(journeyRepositoryProvider);

  @override
  Future<JourneyDashboard> build() => _repository.loadDashboard();

  Future<bool> start() => _mutate(_repository.startJourney);

  Future<bool> refreshProgress() => _mutate(_repository.advanceJourney);

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repository.loadDashboard);
  }

  Future<bool> _mutate(Future<void> Function() operation) async {
    state = const AsyncLoading();
    try {
      await operation();
      state = AsyncData(await _repository.loadDashboard());
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
