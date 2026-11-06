import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_endpoints.dart';
import '../../models/call_session_model.dart';
import '../../models/match_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/call_provider.dart';
import '../../providers/games_provider.dart';
import '../../providers/notifications_provider.dart';
import '../calling/incoming_call_dialog.dart';

class MainNavigationShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  Timer? _callPollingTimer;
  bool _isRingingShown = false;

  @override
  void initState() {
    super.initState();
    _startCallPolling();
  }

  void _startCallPolling() {
    _callPollingTimer?.cancel();
    _callPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated || authState.user == null) return;
      final callState = ref.read(callProvider);
      if (callState.status == CallStatus.connected || callState.status == CallStatus.calling) return;

      try {
        final res = await ApiClient.instance.get(ApiEndpoints.callsActive);
        if (res is Map<String, dynamic>) {
          final call = CallSessionModel.fromJson(res);
          if (call.status == 'CALLING' && call.calleeId == authState.user!.id) {
            if (!_isRingingShown && mounted) {
              _isRingingShown = true;
              _showIncomingCallDialog(call);
            }
          }
        }
      } catch (_) {}
    });
  }

  void _showIncomingCallDialog(CallSessionModel call) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => IncomingCallDialog(
        call: call,
        onAccept: () {
          _isRingingShown = false;
          Navigator.of(ctx).pop();
          final callerProfile = call.caller?['profile'] as Map<String, dynamic>?;
          final callerMatch = MatchModel(
            id: call.matchId,
            otherUserId: call.callerId,
            name: callerProfile?['displayName'] as String? ?? 'Pookie Match',
            city: callerProfile?['city'] as String? ?? 'Nearby',
            bio: 'Live video call',
            image: callerProfile?['imageUrl'] as String?,
          );
          ref.read(callProvider.notifier).acceptCall(call, callerMatch);
          context.push('/video-call');
        },
        onDecline: () {
          _isRingingShown = false;
          Navigator.of(ctx).pop();
          ref.read(callProvider.notifier).declineCall(call.id);
        },
      ),
    );
  }

  @override
  void dispose() {
    _callPollingTimer?.cancel();
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/discover')) return 0;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/matches')) return 2;
    if (location.startsWith('/inventory')) return 3;
    if (location.startsWith('/notifications')) return 4;
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/discover');
        break;
      case 1:
        context.go('/map');
        break;
      case 2:
        context.go('/matches');
        break;
      case 3:
        context.go('/inventory');
        break;
      case 4:
        context.go('/notifications');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final gamesState = ref.watch(gamesProvider);
    final notifsState = ref.watch(notificationsProvider);

    return Scaffold(
      body: Stack(
        children: [
          widget.child,

          // Floating Top Game Invitation Banner
          if (gamesState.pendingIncomingInvite != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(20),
                color: AppColors.callBackground,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.coral.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.coral.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.sports_esports, color: AppColors.coral, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '🎮 Game Challenge',
                              style: TextStyle(color: AppColors.coralLight, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Play ${gamesState.pendingIncomingInvite!.gameLabel}',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          ref.read(gamesProvider.notifier).acceptInvite(gamesState.pendingIncomingInvite!.id);
                          context.go('/games');
                        },
                        child: const Text('Accept', style: TextStyle(fontSize: 11)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                        onPressed: () {
                          ref.read(gamesProvider.notifier).declineInvite(gamesState.pendingIncomingInvite!.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (idx) => _onItemTapped(idx, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.coral,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border, size: 22),
              activeIcon: Icon(Icons.favorite, size: 22),
              label: 'Discover',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined, size: 22),
              activeIcon: Icon(Icons.explore, size: 22),
              label: 'Map',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline, size: 22),
              activeIcon: Icon(Icons.chat_bubble, size: 22),
              label: 'Matches',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard_outlined, size: 22),
              activeIcon: Icon(Icons.card_giftcard, size: 22),
              label: 'Backpack',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, size: 22),
                  if (notifsState.unreadCount > 0)
                    Positioned(
                      top: -3,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '${notifsState.unreadCount > 9 ? '9+' : notifsState.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications, size: 22),
                  if (notifsState.unreadCount > 0)
                    Positioned(
                      top: -3,
                      right: -5,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '${notifsState.unreadCount > 9 ? '9+' : notifsState.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 22),
              activeIcon: Icon(Icons.person, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
