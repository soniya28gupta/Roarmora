class GameParticipantModel {
  final String id;
  final String userId;
  final int score;
  final bool completed;
  final Map<String, dynamic>? answers;
  final Map<String, dynamic>? user;

  GameParticipantModel({
    required this.id,
    required this.userId,
    this.score = 0,
    this.completed = false,
    this.answers,
    this.user,
  });

  factory GameParticipantModel.fromJson(Map<String, dynamic> json) {
    return GameParticipantModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      answers: json['answers'] as Map<String, dynamic>?,
      user: json['user'] as Map<String, dynamic>?,
    );
  }

  String get displayName {
    final profile = user?['profile'] as Map<String, dynamic>?;
    return profile?['displayName'] as String? ?? 'Player';
  }

  String? get imageUrl {
    final profile = user?['profile'] as Map<String, dynamic>?;
    return profile?['imageUrl'] as String?;
  }
}

class GameSessionModel {
  final String id;
  final String gameType; // "COMPATIBILITY_QUIZ" | "VIBE_CHECK" | "TRUTH_OR_DARE" | "TREASURE_RACE"
  final String hostId;
  final String? matchId;
  final String status;   // "INVITED" | "ACTIVE" | "DECLINED" | "COMPLETED" | "EXPIRED"
  final Map<String, dynamic>? state;
  final List<GameParticipantModel> participants;
  final Map<String, dynamic>? host;

  GameSessionModel({
    required this.id,
    required this.gameType,
    required this.hostId,
    this.matchId,
    this.status = 'ACTIVE',
    this.state,
    this.participants = const [],
    this.host,
  });

  factory GameSessionModel.fromJson(Map<String, dynamic> json) {
    return GameSessionModel(
      id: json['id'] as String? ?? '',
      gameType: json['gameType'] as String? ?? 'VIBE_CHECK',
      hostId: json['hostId'] as String? ?? '',
      matchId: json['matchId'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      state: json['state'] as Map<String, dynamic>?,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => GameParticipantModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      host: json['host'] as Map<String, dynamic>?,
    );
  }

  String get gameLabel {
    switch (gameType) {
      case 'COMPATIBILITY_QUIZ':
        return 'Compatibility Quiz';
      case 'VIBE_CHECK':
        return 'Vibe Check Trivia';
      case 'TRUTH_OR_DARE':
        return 'Truth or Dare';
      case 'TREASURE_RACE':
        return 'City Quest Race';
      default:
        return 'Mini-Game';
    }
  }

  String get hostName {
    final profile = host?['profile'] as Map<String, dynamic>?;
    return profile?['displayName'] as String? ?? 'Your Match';
  }
}

