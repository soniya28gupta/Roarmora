import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/match_model.dart';
import '../../providers/matches_provider.dart';
import '../../providers/call_provider.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesProvider);
    final notifier = ref.read(matchesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadMatches(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: notifier.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search mutual matches…',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),

          // Matches List
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
                : state.filteredMatches.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: notifier.loadMatches,
                        color: AppColors.coral,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: state.filteredMatches.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final match = state.filteredMatches[index];
                            return _buildMatchCard(context, ref, match);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.chat_bubble_outline, color: AppColors.coral, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Mutual Matches Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start swiping on Discover to find people with shared interests and values!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/discover'),
              child: const Text('Start Discovering'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, WidgetRef ref, MatchModel match) {
    final comp = match.compatibility?['percentage'] as int? ?? 85;
    final lastText = match.lastMessage?['text'] as String?;

    return InkWell(
      onTap: () => context.push('/chat/${match.id}', extra: match),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.coralSoft,
                  backgroundImage: match.image != null && match.image!.isNotEmpty
                      ? CachedNetworkImageProvider(match.image!)
                      : null,
                  child: match.image == null || match.image!.isEmpty
                      ? Text(
                          match.name.isNotEmpty ? match.name.substring(0, 1).toUpperCase() : 'M',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral, fontSize: 18),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        match.name,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.coralSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$comp%',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.coralDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastText ?? match.bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: lastText != null ? AppColors.ink : AppColors.textMuted,
                      fontWeight: lastText != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),

            // Actions (Chat & Video Call)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.videocam_outlined, color: AppColors.coral, size: 22),
                  onPressed: () {
                    ref.read(callProvider.notifier).initiateCall(match, audioOnly: false);
                    context.push('/video-call');
                  },
                  tooltip: 'Video Call',
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textMuted, size: 20),
                  onPressed: () => context.push('/chat/${match.id}', extra: match),
                  tooltip: 'Open Chat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

