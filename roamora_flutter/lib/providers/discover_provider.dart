import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/match_model.dart';

class DiscoverState {
  final bool isLoading;
  final List<MatchModel> candidates;
  final String? error;
  final MatchModel? lastMatch; // Set when mutual match occurs

  DiscoverState({
    this.isLoading = false,
    this.candidates = const [],
    this.error,
    this.lastMatch,
  });

  DiscoverState copyWith({
    bool? isLoading,
    List<MatchModel>? candidates,
    String? error,
    MatchModel? lastMatch,
    bool clearMatch = false,
  }) {
    return DiscoverState(
      isLoading: isLoading ?? this.isLoading,
      candidates: candidates ?? this.candidates,
      error: error,
      lastMatch: clearMatch ? null : (lastMatch ?? this.lastMatch),
    );
  }
}

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final ApiClient _api = ApiClient.instance;

  DiscoverNotifier() : super(DiscoverState(isLoading: true)) {
    loadCandidates();
  }

  Future<void> loadCandidates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.get(ApiEndpoints.profiles);
      if (data is List) {
        final candidates = data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
        state = state.copyWith(isLoading: false, candidates: candidates);
      } else {
        state = state.copyWith(isLoading: false, candidates: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> swipeLike(MatchModel profile) async {
    final targetId = profile.otherUserId ?? profile.id;
    // Remove immediately from stack for responsive UI
    final updated = state.candidates.where((c) => (c.otherUserId ?? c.id) != targetId).toList();
    state = state.copyWith(candidates: updated);

    try {
      final res = await _api.post(
        ApiEndpoints.swipes,
        data: {'targetId': targetId, 'direction': 'LIKE'},
      );

      if (res is Map && res['matched'] == true) {
        state = state.copyWith(lastMatch: profile);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> swipePass(MatchModel profile) async {
    final targetId = profile.otherUserId ?? profile.id;
    final updated = state.candidates.where((c) => (c.otherUserId ?? c.id) != targetId).toList();
    state = state.copyWith(candidates: updated);

    try {
      await _api.post(
        ApiEndpoints.swipes,
        data: {'targetId': targetId, 'direction': 'PASS'},
      );
    } catch (_) {
      // Ignore
    }
  }

  void clearLastMatch() {
    state = state.copyWith(clearMatch: true);
  }
}

final discoverProvider = StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  return DiscoverNotifier();
});

