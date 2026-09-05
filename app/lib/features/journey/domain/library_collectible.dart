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
  });

  final int id;
  final CollectibleKind kind;
  final String name;
  final String? description;
  final String rarity;
  final DateTime unlockedAt;
  final bool isViewed;
  final bool isEquipped;
}
