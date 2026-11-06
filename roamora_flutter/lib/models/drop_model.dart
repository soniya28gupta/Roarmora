class PlaceModel {
  final String id;
  final String name;
  final String category;
  final String neighborhood;
  final String description;
  final double latitude;
  final double longitude;
  final bool fictional;

  PlaceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.fictional = true,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Café',
      neighborhood: json['neighborhood'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.5535,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.1942,
      fictional: json['fictional'] as bool? ?? true,
    );
  }
}

class DropModel {
  final String id;
  final String title;
  final String description;
  final String interest;
  final DateTime startsAt;
  final String areaLabel;
  final double latitude;
  final double longitude;

  DropModel({
    required this.id,
    required this.title,
    required this.description,
    required this.interest,
    required this.startsAt,
    required this.areaLabel,
    required this.latitude,
    required this.longitude,
  });

  factory DropModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['startsAt'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return DropModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Adventure Drop',
      description: json['description'] as String? ?? '',
      interest: json['interest'] as String? ?? 'Outdoors',
      startsAt: parsedDate,
      areaLabel: json['areaLabel'] as String? ?? 'City Quest',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 28.5535,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 77.1942,
    );
  }
}

