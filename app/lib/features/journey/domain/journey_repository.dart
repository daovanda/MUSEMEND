import 'package:musemend/features/journey/domain/journey_dashboard.dart';

abstract interface class JourneyRepository {
  Future<JourneyDashboard> loadDashboard({required String languageCode});
  Future<void> startJourney();
  Future<void> advanceJourney();
}
