import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/message_model.dart';

class ChatState {
  final bool isLoading;
  final List<MessageModel> messages;
  final bool isSending;
  final String? error;

  ChatState({
    this.isLoading = false,
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    bool? isLoading,
    List<MessageModel>? messages,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final String matchId;
  final ApiClient _api = ApiClient.instance;
  Timer? _pollingTimer;
  String? _currentUserId;

  ChatNotifier(this.matchId) : super(ChatState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await SecureStorageService.getUserId();
    await loadMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      loadMessages(isBackground: true);
    });
  }

  Future<void> loadMessages({bool isBackground = false}) async {
    if (!isBackground) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final data = await _api.get(ApiEndpoints.matchMessages(matchId));
      if (data is List) {
        final rawMessages = data
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>, currentUserId: _currentUserId))
            .toList();

        // Deduplicate messages by ID
        final Map<String, MessageModel> dedup = {};
        for (final m in rawMessages) {
          dedup[m.id] = m;
        }

        // Sort chronologically (oldest first)
        final sorted = dedup.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        state = state.copyWith(isLoading: false, messages: sorted);
      }
    } catch (e) {
      if (!isBackground) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  Future<bool> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return false;

    state = state.copyWith(isSending: true);
    try {
      await _api.post(
        ApiEndpoints.matchMessages(matchId),
        data: {'body': clean},
      );
      state = state.copyWith(isSending: false);
      await loadMessages(isBackground: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, matchId) {
  return ChatNotifier(matchId);
});
