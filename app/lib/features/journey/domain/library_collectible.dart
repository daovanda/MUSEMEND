enum CollectibleKind { landmark, food, item }

class LibraryCollectible {
  const LibraryCollectible({
    required this.id,
    required this.kind,
    required this.name,
    required this.description,
    required this.rarity,
    required this.unlockedAt,
    required this.isViewed,
    this.isEquipped = false,
    this.assetPath,
  });

  final int id;
  final CollectibleKind kind;
  final String name;
  final String? description;
  final String rarity;
  final DateTime unlockedAt;
  final bool isViewed;
  final bool isEquipped;

  /// Catalog asset path resolved by the repository. Null is a valid state
  /// while an official export is still pending.
  final String? assetPath;
}
