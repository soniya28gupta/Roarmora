import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/game_session_model.dart';
import '../models/match_model.dart';

class GamesState {
  final bool isLoading;
  final String activeTab; // 'quiz' | 'trivia' | 'truth_dare' | 'quest'
  final String playMode;  // 'solo' | 'multiplayer'
  final GameSessionModel? activeSession;
  final GameSessionModel? pendingIncomingInvite;
  final List<MatchModel> availableMatches;
  final String? selectedMatchId;
  final int soloTriviaScore;
  final int questStep;
  final String? statusMessage;
  final String? error;

  GamesState({
    this.isLoading = false,
    this.activeTab = 'quiz',
    this.playMode = 'solo',
    this.activeSession,
    this.pendingIncomingInvite,
    this.availableMatches = const [],
    this.selectedMatchId,
    this.soloTriviaScore = 0,
    this.questStep = 0,
    this.statusMessage,
    this.error,
  });

  GamesState copyWith({
    bool? isLoading,
    String? activeTab,
    String? playMode,
    GameSessionModel? activeSession,
    GameSessionModel? pendingIncomingInvite,
    List<MatchModel>? availableMatches,
    String? selectedMatchId,
    int? soloTriviaScore,
    int? questStep,
    String? statusMessage,
    String? error,
    bool clearActiveSession = false,
    bool clearPendingInvite = false,
    bool clearStatus = false,
  }) {
    return GamesState(
      isLoading: isLoading ?? this.isLoading,
      activeTab: activeTab ?? this.activeTab,
      playMode: playMode ?? this.playMode,
      activeSession: clearActiveSession ? null : (activeSession ?? this.activeSession),
      pendingIncomingInvite: clearPendingInvite ? null : (pendingIncomingInvite ?? this.pendingIncomingInvite),
      availableMatches: availableMatches ?? this.availableMatches,
      selectedMatchId: selectedMatchId ?? this.selectedMatchId,
      soloTriviaScore: soloTriviaScore ?? this.soloTriviaScore,
      questStep: questStep ?? this.questStep,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
      error: error,
    );
  }
}

class GamesNotifier extends StateNotifier<GamesState> {
  final ApiClient _api = ApiClient.instance;
  Timer? _sessionPollingTimer;
  Timer? _invitesPollingTimer;
  String? _myUserId;

  GamesNotifier() : super(GamesState()) {
    _init();
  }

  Future<void> _init() async {
    _myUserId = await SecureStorageService.getUserId();
    await loadMatches();
    _startInvitesPolling();
  }

  Future<void> loadMatches() async {
    try {
      final data = await _api.get(ApiEndpoints.matches);
      if (data is List) {
        final matches = data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
        state = state.copyWith(
          availableMatches: matches,
          selectedMatchId: matches.isNotEmpty ? matches.first.id : null,
        );
      }
    } catch (_) {}
  }

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setPlayMode(String mode) {
    state = state.copyWith(playMode: mode);
  }

  void setSelectedMatchId(String matchId) {
    state = state.copyWith(selectedMatchId: matchId);
  }

  // 1. Send Game Invitation
  Future<bool> sendGameInvitation(String matchId, String gameType) async {
    state = state.copyWith(isLoading: true, clearStatus: true);
    try {
      final res = await _api.post(
        ApiEndpoints.gamesInvite,
        data: {'matchId': matchId, 'gameType': gameType},
      );

      final session = GameSessionModel.fromJson(res as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        activeSession: session,
        playMode: 'multiplayer',
        statusMessage: 'Invitation sent! Waiting for your match to accept...',
      );

      _startSessionPolling(session.id);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // 2. Poll for incoming invitations
  void _startInvitesPolling() {
    _invitesPollingTimer?.cancel();
    _invitesPollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (state.activeSession != null) return;
      try {
        final data = await _api.get(ApiEndpoints.gamesInvites);
        if (data is List && data.isNotEmpty) {
          final invite = GameSessionModel.fromJson(data.first as Map<String, dynamic>);
          if (invite.status == 'INVITED' && invite.hostId != _myUserId) {
            state = state.copyWith(pendingIncomingInvite: invite);
          } else {
            state = state.copyWith(clearPendingInvite: true);
          }
        }
      } catch (_) {}
    });
  }

  // 3. Accept / Decline Invite
  Future<void> acceptInvite(String sessionId) async {
    try {
      await _api.post(ApiEndpoints.gameAccept(sessionId));
      final res = await _api.get(ApiEndpoints.gameSession(sessionId));
      final session = GameSessionModel.fromJson(res as Map<String, dynamic>);
      state = state.copyWith(
        activeSession: session,
        playMode: 'multiplayer',
        clearPendingInvite: true,
      );
      _startSessionPolling(sessionId);
    } catch (_) {}
  }

  Future<void> declineInvite(String sessionId) async {
    try {
      await _api.post(ApiEndpoints.gameDecline(sessionId));
    } catch (_) {}
    state = state.copyWith(clearPendingInvite: true);
  }

  // 4. Poll active multiplayer session
  void _startSessionPolling(String sessionId) {
    _sessionPollingTimer?.cancel();
    _sessionPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        final res = await _api.get(ApiEndpoints.gameSession(sessionId));
        if (res is Map<String, dynamic>) {
          final updated = GameSessionModel.fromJson(res);
          state = state.copyWith(activeSession: updated);
        }
      } catch (_) {}
    });
  }

  // 5. Submit multiplayer game action
  Future<void> submitGameAction(String action, Map<String, dynamic> payload) async {
    final session = state.activeSession;
    if (session == null) return;

    try {
      await _api.post(
        ApiEndpoints.gameAction(session.id),
        data: {'action': action, 'payload': payload},
      );
    } catch (_) {}
  }

  // Solo mode controls
  void addTriviaScore(int points) {
    state = state.copyWith(soloTriviaScore: state.soloTriviaScore + points);
  }

  void advanceQuest() {
    state = state.copyWith(questStep: state.questStep + 1);
  }

  @override
  void dispose() {
    _sessionPollingTimer?.cancel();
    _invitesPollingTimer?.cancel();
    super.dispose();
  }
}

final gamesProvider = StateNotifierProvider<GamesNotifier, GamesState>((ref) {
  return GamesNotifier();
});

