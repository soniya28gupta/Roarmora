class MatchModel {
  final String id;
  final String? otherUserId;
  final String name;
  final int age;
  final String city;
  final String bio;
  final List<String> interests;
  final String? image;
  final List<String> photos;
  final Map<String, dynamic>? lastMessage;
  final Map<String, dynamic>? compatibility;
  final double? latitude;
  final double? longitude;
  final bool? locationShared;
  final String? lastLocationTime;

  MatchModel({
    required this.id,
    this.otherUserId,
    required this.name,
    this.age = 24,
    required this.city,
    required this.bio,
    this.interests = const [],
    this.image,
    this.photos = const [],
    this.lastMessage,
    this.compatibility,
    this.latitude,
    this.longitude,
    this.locationShared,
    this.lastLocationTime,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? json;

    return MatchModel(
      id: json['id'] as String? ?? profile['id'] as String? ?? '',
      otherUserId: profile['id'] as String? ?? json['otherUserId'] as String?,
      name: profile['displayName'] as String? ?? profile['name'] as String? ?? 'Roamora Match',
      age: profile['age'] as int? ?? 24,
      city: profile['city'] as String? ?? 'Nearby',
      bio: profile['bio'] as String? ?? '',
      interests: (profile['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      image: profile['imageUrl'] as String? ?? profile['image'] as String?,
      photos: (profile['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      lastMessage: json['lastMessage'] as Map<String, dynamic>?,
      compatibility: profile['compatibility'] as Map<String, dynamic>?,
      latitude: (profile['latitude'] as num?)?.toDouble() ?? (json['latitude'] as num?)?.toDouble(),
      longitude: (profile['longitude'] as num?)?.toDouble() ?? (json['longitude'] as num?)?.toDouble(),
      locationShared: profile['locationConsent'] as bool? ?? json['locationShared'] as bool?,
      lastLocationTime: json['lastLocationTime'] as String?,
    );
  }
}
