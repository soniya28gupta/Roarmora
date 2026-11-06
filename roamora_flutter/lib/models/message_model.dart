class MessageModel {
  final String id;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final bool fromMe;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.fromMe = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final sender = json['senderId'] as String? ?? '';
    DateTime parsedDate;
    try {
      final raw = json['createdAt'] as String;
      // Ensure UTC string parses properly and converts to device's local timezone (e.g. Asia/Kolkata)
      final utc = raw.endsWith('Z') || raw.contains('+') ? DateTime.parse(raw) : DateTime.parse('${raw}Z');
      parsedDate = utc.toLocal();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return MessageModel(
      id: json['id'] as String? ?? '',
      senderId: sender,
      body: json['body'] as String? ?? '',
      createdAt: parsedDate,
      fromMe: currentUserId != null ? sender == currentUserId : (json['fromMe'] as bool? ?? false),
    );
  }
}
