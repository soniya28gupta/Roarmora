class CallSessionModel {
  final String id;
  final String callerId;
  final String calleeId;
  final String matchId;
  final String callType; // "AUDIO" | "VIDEO"
  final String status;   // "CALLING" | "ACCEPTED" | "DECLINED" | "ENDED" | "MISSED" | "SKIPPED"
  final Map<String, dynamic>? offer;
  final Map<String, dynamic>? answer;
  final List<dynamic>? candidates;
  final Map<String, dynamic>? caller;
  final Map<String, dynamic>? callee;
  final DateTime? startedAt;
  final DateTime? endedAt;

  CallSessionModel({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.matchId,
    this.callType = 'VIDEO',
    this.status = 'CALLING',
    this.offer,
    this.answer,
    this.candidates,
    this.caller,
    this.callee,
    this.startedAt,
    this.endedAt,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    return CallSessionModel(
      id: json['id'] as String? ?? '',
      callerId: json['callerId'] as String? ?? '',
      calleeId: json['calleeId'] as String? ?? '',
      matchId: json['matchId'] as String? ?? '',
      callType: json['callType'] as String? ?? 'VIDEO',
      status: json['status'] as String? ?? 'CALLING',
      offer: json['offer'] as Map<String, dynamic>?,
      answer: json['answer'] as Map<String, dynamic>?,
      candidates: json['candidates'] as List<dynamic>?,
      caller: json['caller'] as Map<String, dynamic>?,
      callee: json['callee'] as Map<String, dynamic>?,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'].toString()) : null,
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt'].toString()) : null,
    );
  }

  String get callerName {
    final profile = caller?['profile'] as Map<String, dynamic>?;
    return profile?['displayName'] as String? ?? 'Roamora Match';
  }

  String? get callerImage {
    final profile = caller?['profile'] as Map<String, dynamic>?;
    return profile?['imageUrl'] as String?;
  }
}

