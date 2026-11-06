import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/pookie_brand_mark.dart';
import '../../models/match_model.dart';
import '../../providers/discover_provider.dart';
import '../../providers/call_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverProvider);
    final notifier = ref.read(discoverProvider.notifier);

    // Mutual Match Celebration Dialog
    if (state.lastMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMutualMatchDialog(context, ref, state.lastMatch!);
        notifier.clearLastMatch();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const PookieBrandMark(size: 26, fontSize: 18),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_esports_outlined, color: AppColors.coral),
            onPressed: () => context.push('/games'),
            tooltip: 'Play Mini-Games',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadCandidates(),
            tooltip: 'Refresh discovery radar',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            )
          : state.candidates.isEmpty
              ? _buildEmptyState(context, notifier)
              : _buildCardStack(context, state.candidates, notifier),
    );
  }

  Widget _buildEmptyState(BuildContext context, DiscoverNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'You’ve Caught Up!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              'No new profiles matching your filters right now. Explore the Adventure Map to discover city drops and unlock achievements!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/map'),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Open Adventure Map'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => notifier.loadCandidates(),
              child: const Text('Refresh Radar', style: TextStyle(color: AppColors.coral)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack(BuildContext context, List<MatchModel> candidates, DiscoverNotifier notifier) {
    final candidate = candidates.first;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _buildProfileCard(context, candidate),
          ),
        ),

        // Action Buttons Row (Pass / Like)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pass Button (X)
              InkWell(
                onTap: () => notifier.swipePass(candidate),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: AppColors.textMuted, size: 30),
                ),
              ),
              const SizedBox(width: 32),

              // Like Button (Heart)
              InkWell(
                onTap: () => notifier.swipeLike(candidate),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 34),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, MatchModel candidate) {
    final compPercent = candidate.compatibility?['percentage'] as int? ?? 88;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          candidate.image != null && candidate.image!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: candidate.image!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.coralSoft,
                    child: const Center(child: CircularProgressIndicator(color: AppColors.coral)),
                  ),
                  errorWidget: (context, url, error) => _buildAvatarFallback(candidate),
                )
              : _buildAvatarFallback(candidate),

          // Gradient overlay at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 260,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Compatibility Badge at top right
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨ ', style: TextStyle(fontSize: 12)),
                  Text(
                    '$compPercent% Match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details at bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      candidate.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${candidate.age}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: AppColors.coralLight, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      candidate.city,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                if (candidate.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    candidate.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                ],
                const SizedBox(height: 12),
                // Interests chips
                if (candidate.interests.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: candidate.interests.take(4).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(MatchModel candidate) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.coralLight, AppColors.coralDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          candidate.name.isNotEmpty ? candidate.name.substring(0, 1).toUpperCase() : 'M',
          style: const TextStyle(fontSize: 72, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showMutualMatchDialog(BuildContext context, WidgetRef ref, MatchModel match) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💖', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text(
                'It’s a Match!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'You and ${match.name} expressed mutual interest.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/chat/${match.id}', extra: match);
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Send a Message'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ref.read(callProvider.notifier).initiateCall(match, audioOnly: false);
                  context.push('/video-call');
                },
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Start Video Call'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Keep Browsing', style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

