import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/pookie_brand_mark.dart';
import '../../models/notification_model.dart';
import '../../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _filter = 'all'; // 'all' or 'unread'

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Widget _getNotificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MATCH':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.coralPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.favorite, color: AppColors.coral, size: 20),
        );
      case 'MESSAGE':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.chat_bubble, color: Color(0xFF3B82F6), size: 20),
        );
      case 'COLLECTIBLE':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.card_giftcard, color: Color(0xFFD97706), size: 20),
        );
      case 'ACHIEVEMENT':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.emoji_events, color: Color(0xFF7C3AED), size: 20),
        );
      case 'CALL':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.videocam, color: AppColors.success, size: 20),
        );
      case 'INVITE':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE7F3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.sports_esports, color: Color(0xFFDB2777), size: 20),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.coralPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications, color: AppColors.coral, size: 20),
        );
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    if (!notification.read) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    switch (notification.type.toUpperCase()) {
      case 'MATCH':
      case 'MESSAGE':
        context.go('/matches');
        break;
      case 'INVITE':
        context.go('/games');
        break;
      case 'COLLECTIBLE':
      case 'ACHIEVEMENT':
        context.go('/inventory');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final displayedList = _filter == 'unread'
        ? state.notifications.where((n) => !n.read).toList()
        : state.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const PookieBrandMark(size: 26, fontSize: 18),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.done_all, size: 16, color: AppColors.coral),
              label: const Text('Read all', style: TextStyle(color: AppColors.coral, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notificationsProvider.notifier).loadNotifications(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(),
        child: Column(
          children: [
            // Filter Header matching website
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Alerts (${state.notifications.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('unread', 'Unread (${state.unreadCount})'),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // Notifications List
            Expanded(
              child: displayedList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppColors.coralPale,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.notifications_none, size: 32, color: AppColors.coral),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filter == 'unread' ? 'No Unread Alerts' : 'No Alerts Yet',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Matches, game invites, and exploration drops will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.all(16),
                      itemCount: displayedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = displayedList[index];

                        return InkWell(
                          onTap: () => _handleNotificationTap(item),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.read ? Colors.white : const Color(0xFFFFF9F8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: item.read ? AppColors.border : const Color(0xFFFFD4D1),
                                width: item.read ? 1 : 1.2,
                              ),
                              boxShadow: item.read ? null : AppColors.subtleShadow,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _getNotificationIcon(item.type),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.title,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: item.read ? FontWeight.w600 : FontWeight.bold,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          if (!item.read)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: const BoxDecoration(
                                                color: AppColors.coral,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          Text(
                                            _formatRelativeTime(item.createdAt.toLocal()),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.body,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;

    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.coral : const Color(0xFFF4ECEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

