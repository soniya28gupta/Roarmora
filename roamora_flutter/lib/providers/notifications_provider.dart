import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/notification_model.dart';
import '../models/collectible_model.dart';
import '../models/achievement_model.dart';

class NotificationsState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final List<CollectibleItemModel> inventory;
  final List<AchievementModel> achievements;
  final int totalPoints;
  final List<Map<String, dynamic>> blockedUsers;
  final String? error;

  NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadCount = 0,
    this.inventory = const [],
    this.achievements = const [],
    this.totalPoints = 0,
    this.blockedUsers = const [],
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    List<CollectibleItemModel>? inventory,
    List<AchievementModel>? achievements,
    int? totalPoints,
    List<Map<String, dynamic>>? blockedUsers,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      inventory: inventory ?? this.inventory,
      achievements: achievements ?? this.achievements,
      totalPoints: totalPoints ?? this.totalPoints,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      error: error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _api = ApiClient.instance;
  Timer? _pollingTimer;

  NotificationsNotifier() : super(NotificationsState()) {
    init();
  }

  Future<void> init() async {
    await Future.wait([
      loadNotifications(),
      loadInventory(),
      loadAchievements(),
      loadBlockedUsers(),
    ]);
    _pollingTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      loadNotifications(silent: true);
    });
  }

  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiEndpoints.notifications);
      if (res is Map<String, dynamic>) {
        final list = (res['notifications'] as List<dynamic>?)
                ?.map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [];
        final unread = res['unreadCount'] as int? ?? 0;
        state = state.copyWith(
          isLoading: false,
          notifications: list,
          unreadCount: unread,
        );
      }
    } catch (_) {
      if (!silent) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _api.patch(ApiEndpoints.notificationRead(id));
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all');
      state = state.copyWith(
        notifications: state.notifications.map((n) => n.copyWith(read: true)).toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  Future<void> loadInventory() async {
    try {
      final data = await _api.get(ApiEndpoints.inventory);
      if (data is List) {
        final items = data.map((json) => CollectibleItemModel.fromJson(json as Map<String, dynamic>)).toList();
        state = state.copyWith(inventory: items);
      }
    } catch (_) {}
  }

  Future<void> loadAchievements() async {
    try {
      final data = await _api.get(ApiEndpoints.achievements);
      if (data is Map<String, dynamic>) {
        final list = (data['achievements'] as List<dynamic>?)
                ?.map((json) => AchievementModel.fromJson(json as Map<String, dynamic>))
                .toList() ??
            [];
        final points = data['totalPoints'] as int? ?? 0;
        state = state.copyWith(achievements: list, totalPoints: points);
      }
    } catch (_) {}
  }

  Future<void> loadBlockedUsers() async {
    try {
      final data = await _api.get(ApiEndpoints.blocks);
      if (data is List) {
        state = state.copyWith(blockedUsers: List<Map<String, dynamic>>.from(data));
      }
    } catch (_) {}
  }

  Future<bool> unblockUser(String userId) async {
    try {
      await _api.delete(ApiEndpoints.unblock(userId));
      await loadBlockedUsers();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});
