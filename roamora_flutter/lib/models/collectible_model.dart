class CollectibleItemModel {
  final String id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String rarity;
  final String category;
  final String? perkDescription;
  final double? latitude;
  final double? longitude;
  final int quantity;

  CollectibleItemModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    this.rarity = 'COMMON',
    this.category = 'Adventure',
    this.perkDescription,
    this.latitude,
    this.longitude,
    this.quantity = 1,
  });

  factory CollectibleItemModel.fromJson(Map<String, dynamic> json) {
    final itemData = json['item'] as Map<String, dynamic>? ?? json;

    return CollectibleItemModel(
      id: itemData['id'] as String? ?? json['id'] as String? ?? '',
      name: itemData['name'] as String? ?? 'Exploration Trinket',
      slug: itemData['slug'] as String? ?? '',
      description: itemData['description'] as String? ?? '',
      icon: itemData['icon'] as String? ?? '🎁',
      rarity: itemData['rarity'] as String? ?? 'COMMON',
      category: itemData['category'] as String? ?? 'Adventure',
      perkDescription: itemData['perkDescription'] as String?,
      latitude: (itemData['latitude'] as num?)?.toDouble(),
      longitude: (itemData['longitude'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
    );
  }
}
