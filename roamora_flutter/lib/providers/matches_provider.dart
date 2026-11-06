import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/match_model.dart';

class MatchesState {
  final bool isLoading;
  final List<MatchModel> matches;
  final String searchQuery;
  final String? error;

  MatchesState({
    this.isLoading = false,
    this.matches = const [],
    this.searchQuery = '',
    this.error,
  });

  List<MatchModel> get filteredMatches {
    if (searchQuery.trim().isEmpty) return matches;
    final q = searchQuery.toLowerCase().trim();
    return matches.where((m) => m.name.toLowerCase().contains(q) || m.city.toLowerCase().contains(q)).toList();
  }

  MatchesState copyWith({
    bool? isLoading,
    List<MatchModel>? matches,
    String? searchQuery,
    String? error,
  }) {
    return MatchesState(
      isLoading: isLoading ?? this.isLoading,
      matches: matches ?? this.matches,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

class MatchesNotifier extends StateNotifier<MatchesState> {
  final ApiClient _api = ApiClient.instance;

  MatchesNotifier() : super(MatchesState(isLoading: true)) {
    loadMatches();
  }

  Future<void> loadMatches() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _api.get(ApiEndpoints.matches);
      if (data is List) {
        final matches = data.map((json) => MatchModel.fromJson(json as Map<String, dynamic>)).toList();
        state = state.copyWith(isLoading: false, matches: matches);
      } else {
        state = state.copyWith(isLoading: false, matches: []);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> unmatch(String matchId) async {
    try {
      await _api.delete('${ApiEndpoints.matches}/$matchId');
      final updated = state.matches.where((m) => m.id != matchId).toList();
      state = state.copyWith(matches: updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> blockUser(String userId) async {
    try {
      await _api.post(ApiEndpoints.blocks, data: {'blockedId': userId});
      final updated = state.matches.where((m) => m.otherUserId != userId).toList();
      state = state.copyWith(matches: updated);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final matchesProvider = StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  return MatchesNotifier();
});

