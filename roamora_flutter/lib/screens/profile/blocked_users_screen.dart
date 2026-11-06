import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notifications_provider.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: state.blockedUsers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.coralSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_outlined, color: AppColors.coral, size: 32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Blocked Users',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Users you block will appear here. You can unblock them at any time to make them eligible for discovery again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.blockedUsers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final block = state.blockedUsers[index];
                final target = block['blocked'] as Map<String, dynamic>? ?? {};
                final profile = target['profile'] as Map<String, dynamic>? ?? {};
                final name = profile['displayName'] as String? ?? 'Blocked Member';
                final userId = target['id'] as String? ?? block['blockedId'] as String? ?? '';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.coralSoft,
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.ink),
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          minimumSize: const Size(80, 32),
                        ),
                        onPressed: () => _confirmUnblock(context, notifier, userId, name),
                        child: const Text('Unblock', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _confirmUnblock(BuildContext context, NotificationsNotifier notifier, String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unblock $name?'),
        content: Text('$name will become eligible to appear in Discover results again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await notifier.unblockUser(userId);
            },
            child: const Text('Confirm Unblock'),
          ),
        ],
      ),
    );
  }
}

