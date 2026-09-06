import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_province.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';

class JourneyDashboardMapper {
  const JourneyDashboardMapper();

  JourneyDashboard fromResponses(List<dynamic> responses) {
    if (responses.length != 11) {
      throw const FormatException('Incomplete journey dashboard response.');
    }

    final progress = _object(responses[0]);
    final provinces = _rows(responses[1]);
    final checkpoints = _rows(responses[2]);
    final checkpointProgress = _rows(responses[3]);
    final unlockedProvinces = _rows(responses[4]);
    final unlockedLandmarks = _rows(responses[5]);
    final unlockedFoods = _rows(responses[6]);
    final unlockedItems = _rows(responses[7]);
    final landmarks = _rowsById(responses[8]);
    final foods = _rowsById(responses[9]);
    final items = _rowsById(responses[10]);

    final currentProvinceId = _nullableInt(progress['current_province_id']);
    final currentCheckpointId = _nullableInt(progress['current_checkpoint_id']);
    final provinceRow = _findById(provinces, currentProvinceId);
    final progressByCheckpoint = <int, Map<String, dynamic>>{
      for (final row in checkpointProgress)
        (row['checkpoint_id'] as num).toInt(): row,
    };

    JourneyProvince? province;
    if (provinceRow != null && currentProvinceId != null) {
      final provinceCheckpoints = checkpoints
        .where(
          (row) => (row['province_id'] as num).toInt() == currentProvinceId,
        )
        .map((row) {
          final id = (row['id'] as num).toInt();
          final saved = progressByCheckpoint[id];
          return JourneyCheckpoint(
            id: id,
            number: (row['checkpoint_number'] as num).toInt(),
            title: row['title'] as String,
            description: row['description'] as String?,
            requiredEnergy: (row['required_energy'] as num).toInt(),
            earnedEnergy: (saved?['earned_energy'] as num?)?.toInt() ?? 0,
            status: saved?['status'] as String? ?? 'locked',
          );
        })
        .toList(growable: false)..sort((a, b) => a.number.compareTo(b.number));
      final unlocked = unlockedProvinces
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (row) =>
                row != null &&
                (row['province_id'] as num).toInt() == currentProvinceId,
            orElse: () => null,
          );
      province = JourneyProvince(
        id: currentProvinceId,
        name: provinceRow['name'] as String,
        description: provinceRow['description'] as String?,
        completionPercent:
            (unlocked?['completion_percent'] as num?)?.toInt() ?? 0,
        checkpoints: provinceCheckpoints,
        coverAssetPath: provinceRow['cover_asset_path'] as String?,
        mapAssetPath: provinceRow['map_asset_path'] as String?,
      );
    }

    final collectibles = <LibraryCollectible>[
      ..._collectibles(
        unlockedLandmarks,
        landmarks,
        foreignKey: 'landmark_id',
        kind: CollectibleKind.landmark,
      ),
      ..._collectibles(
        unlockedFoods,
        foods,
        foreignKey: 'food_id',
        kind: CollectibleKind.food,
      ),
      ..._collectibles(
        unlockedItems,
        items,
        foreignKey: 'province_item_id',
        kind: CollectibleKind.item,
      ),
    ]..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

    return JourneyDashboard(
      status: JourneyStatus.fromDatabase(progress['journey_status'] as String),
      currentEnergy: (progress['current_energy'] as num).toInt(),
      journeyEnergyUsed: (progress['journey_energy_used'] as num).toInt(),
      province: province,
      currentCheckpointId: currentCheckpointId,
      collectibles: collectibles,
    );
  }

  List<LibraryCollectible> _collectibles(
    List<Map<String, dynamic>> unlocks,
    Map<int, Map<String, dynamic>> catalog, {
    required String foreignKey,
    required CollectibleKind kind,
  }) {
    return unlocks
        .map((unlock) {
          final id = (unlock[foreignKey] as num).toInt();
          final item = catalog[id];
          if (item == null) {
            throw FormatException('Unlocked catalog item $id is unavailable.');
          }
          return LibraryCollectible(
            id: id,
            kind: kind,
            name: item['name'] as String,
            description: item['description'] as String?,
            rarity: item['rarity'] as String,
            unlockedAt: DateTime.parse(unlock['unlocked_at'] as String),
            isViewed: unlock['is_viewed'] as bool,
            isEquipped: unlock['is_equipped'] as bool? ?? false,
            assetPath: item['asset_path'] as String?,
          );
        })
        .toList(growable: false);
  }

  Map<int, Map<String, dynamic>> _rowsById(Object? value) {
    return {for (final row in _rows(value)) (row['id'] as num).toInt(): row};
  }

  Map<String, dynamic>? _findById(List<Map<String, dynamic>> rows, int? id) {
    if (id == null) return null;
    for (final row in rows) {
      if ((row['id'] as num).toInt() == id) return row;
    }
    return null;
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected a journey object.');
    }
    return Map<String, dynamic>.from(value);
  }

  List<Map<String, dynamic>> _rows(Object? value) {
    if (value is! List) {
      throw const FormatException('Expected journey rows.');
    }
    return value
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  int? _nullableInt(Object? value) => (value as num?)?.toInt();
}
