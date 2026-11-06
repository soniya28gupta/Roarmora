class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? link;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.link,
    this.read = false,
    required this.createdAt,
  });

  String get body => message;

  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    String? link,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      link: link ?? this.link,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final raw = json['createdAt'] as String;
      final utc = raw.endsWith('Z') || raw.contains('+') ? DateTime.parse(raw) : DateTime.parse('${raw}Z');
      parsedDate = utc.toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'ALERT',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      link: json['link'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }
}
