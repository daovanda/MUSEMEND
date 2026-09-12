import 'package:musemend/features/journey/domain/journey_checkpoint.dart';
import 'package:musemend/features/journey/domain/journey_dashboard.dart';
import 'package:musemend/features/journey/domain/journey_destination.dart';
import 'package:musemend/features/journey/domain/journey_status.dart';
import 'package:musemend/features/journey/domain/library_collectible.dart';

class JourneyDashboardMapper {
  const JourneyDashboardMapper();

  JourneyDashboard fromResponses(
    List<dynamic> responses, {
    required String languageCode,
  }) {
    if (responses.length != 11) {
      throw const FormatException('Incomplete journey dashboard response.');
    }

    final progress = _object(responses[0]);
    final destinations = _rows(responses[1]);
    final checkpoints = _rows(responses[2]);
    final checkpointProgress = _rows(responses[3]);
    final unlockedDestinations = _rows(responses[4]);
    final unlockedLandmarks = _rows(responses[5]);
    final unlockedFoods = _rows(responses[6]);
    final unlockedItems = _rows(responses[7]);
    final landmarks = _rowsById(responses[8]);
    final foods = _rowsById(responses[9]);
    final items = _rowsById(responses[10]);

    final currentDestinationId = _nullableInt(
      progress['current_destination_id'],
    );
    final currentCheckpointId = _nullableInt(progress['current_checkpoint_id']);
    final destinationRow = _findById(destinations, currentDestinationId);
    final progressByCheckpoint = <int, Map<String, dynamic>>{
      for (final row in checkpointProgress)
        (row['checkpoint_id'] as num).toInt(): row,
    };

    JourneyDestination? destination;
    if (destinationRow != null && currentDestinationId != null) {
      final destinationCheckpoints = checkpoints
        .where(
          (row) =>
              (row['destination_id'] as num).toInt() == currentDestinationId,
        )
        .map((row) {
          final id = (row['id'] as num).toInt();
          final saved = progressByCheckpoint[id];
          final copy = _withTranslation(
            row,
            relation: 'checkpoint_translations',
            languageCode: languageCode,
            fields: const ['title', 'description'],
          );
          return JourneyCheckpoint(
            id: id,
            number: (row['checkpoint_number'] as num).toInt(),
            title: copy['title'] as String,
            description: copy['description'] as String?,
            requiredEnergy: (row['required_energy'] as num).toInt(),
            earnedEnergy: (saved?['earned_energy'] as num?)?.toInt() ?? 0,
            status: saved?['status'] as String? ?? 'locked',
            assetPath: row['asset_path'] as String?,
          );
        })
        .toList(growable: false)..sort((a, b) => a.number.compareTo(b.number));
      final unlocked = unlockedDestinations
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (row) =>
                row != null &&
                (row['destination_id'] as num).toInt() == currentDestinationId,
            orElse: () => null,
          );
      final destinationCopy = _withTranslation(
        destinationRow,
        relation: 'destination_translations',
        languageCode: languageCode,
        fields: const ['name', 'description'],
      );
      destination = JourneyDestination(
        id: currentDestinationId,
        name: destinationCopy['name'] as String,
        description: destinationCopy['description'] as String?,
        countryCode: destinationRow['country_code'] as String?,
        destinationType:
            destinationRow['destination_type'] as String? ?? 'region',
        completionPercent:
            (unlocked?['completion_percent'] as num?)?.toInt() ?? 0,
        checkpoints: destinationCheckpoints,
        coverAssetPath: destinationRow['cover_asset_path'] as String?,
        mapAssetPath: destinationRow['map_asset_path'] as String?,
      );
    }

    final collectibles = <LibraryCollectible>[
      ..._collectibles(
        unlockedLandmarks,
        landmarks,
        foreignKey: 'landmark_id',
        kind: CollectibleKind.landmark,
        translationRelation: 'landmark_translations',
        languageCode: languageCode,
      ),
      ..._collectibles(
        unlockedFoods,
        foods,
        foreignKey: 'food_id',
        kind: CollectibleKind.food,
        translationRelation: 'food_translations',
        languageCode: languageCode,
      ),
      ..._collectibles(
        unlockedItems,
        items,
        foreignKey: 'destination_item_id',
        kind: CollectibleKind.item,
        translationRelation: 'destination_item_translations',
        languageCode: languageCode,
      ),
    ]..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));

    return JourneyDashboard(
      status: JourneyStatus.fromDatabase(progress['journey_status'] as String),
      currentEnergy: (progress['current_energy'] as num).toInt(),
      journeyEnergyUsed: (progress['journey_energy_used'] as num).toInt(),
      destination: destination,
      currentCheckpointId: currentCheckpointId,
      collectibles: collectibles,
    );
  }

  List<LibraryCollectible> _collectibles(
    List<Map<String, dynamic>> unlocks,
    Map<int, Map<String, dynamic>> catalog, {
    required String foreignKey,
    required CollectibleKind kind,
    required String translationRelation,
    required String languageCode,
  }) {
    return unlocks
        .map((unlock) {
          final id = (unlock[foreignKey] as num).toInt();
          final item = catalog[id];
          if (item == null) {
            throw FormatException('Unlocked catalog item $id is unavailable.');
          }
          final copy = _withTranslation(
            item,
            relation: translationRelation,
            languageCode: languageCode,
            fields: const ['name', 'description'],
          );
          return LibraryCollectible(
            id: id,
            kind: kind,
            name: copy['name'] as String,
            description: copy['description'] as String?,
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

  Map<String, dynamic> _withTranslation(
    Map<String, dynamic> row, {
    required String relation,
    required String languageCode,
    required List<String> fields,
  }) {
    final copy = Map<String, dynamic>.from(row);
    final translations = (row[relation] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);
    Map<String, dynamic>? selected;
    for (final code in [languageCode, 'en']) {
      for (final translation in translations) {
        if (translation['language_code'] == code) {
          selected = translation;
          break;
        }
      }
      if (selected != null) break;
    }
    if (selected != null) {
      for (final field in fields) {
        if (selected[field] != null) copy[field] = selected[field];
      }
    }
    return copy;
  }
}
