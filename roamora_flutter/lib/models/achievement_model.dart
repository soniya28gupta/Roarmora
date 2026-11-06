class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String badgeIcon;
  final int points;
  final bool unlocked;
  final String? unlockedAt;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.badgeIcon,
    required this.points,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Achievement',
      description: json['description'] as String? ?? '',
      badgeIcon: json['badgeIcon'] as String? ?? json['icon'] as String? ?? '🏆',
      points: json['points'] as int? ?? 10,
      unlocked: json['unlocked'] as bool? ?? (json['unlockedAt'] != null),
      unlockedAt: json['unlockedAt'] as String?,
    );
  }
}

