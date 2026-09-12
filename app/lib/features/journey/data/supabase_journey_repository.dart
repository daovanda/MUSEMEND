import 'package:musemend/features/journey/data/journey_dashboard_mapper.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseJourneyRepository implements JourneyRepository {
  SupabaseJourneyRepository(this._client);

  final SupabaseClient _client;
  static const _mapper = JourneyDashboardMapper();

  @override
  Future<JourneyDashboard> loadDashboard() async {
    final responses = await Future.wait<dynamic>([
      _client
          .from('travel_progress')
          .select(
            'current_destination_id, current_checkpoint_id, current_energy, '
            'journey_energy_used, journey_status',
          )
          .single(),
      _client
          .from('destinations')
          .select(
            'id, name, description, country_code, destination_type, '
            'cover_asset_path, map_asset_path',
          )
          .eq('is_active', true)
          .order('order_index', ascending: true),
      _client
          .from('destination_checkpoints')
          .select(
            'id, destination_id, checkpoint_number, title, description, '
            'required_energy, asset_path',
          )
          .eq('is_active', true)
          .order('order_index', ascending: true),
      _client
          .from('user_checkpoint_progress')
          .select('checkpoint_id, earned_energy, status'),
      _client
          .from('unlocked_destinations')
          .select('destination_id, completion_percent'),
      _client
          .from('unlocked_landmarks')
          .select('landmark_id, unlocked_at, is_viewed'),
      _client.from('unlocked_foods').select('food_id, unlocked_at, is_viewed'),
      _client
          .from('unlocked_destination_items')
          .select('destination_item_id, unlocked_at, is_viewed, is_equipped'),
      _client
          .from('landmarks')
          .select('id, name, description, rarity, asset_path')
          .eq('is_active', true),
      _client
          .from('foods')
          .select('id, name, description, rarity, asset_path')
          .eq('is_active', true),
      _client
          .from('destination_items')
          .select('id, name, description, rarity, asset_path')
          .eq('is_active', true),
    ]);
    return _mapper.fromResponses(responses);
  }

  @override
  Future<void> startJourney() async {
    await _client.rpc('start_journey');
  }

  @override
  Future<void> advanceJourney() async {
    await _client.rpc('advance_journey');
  }
}
