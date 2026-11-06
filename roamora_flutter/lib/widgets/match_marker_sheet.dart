import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../models/match_model.dart';
import '../providers/call_provider.dart';

class MatchMarkerSheet extends ConsumerWidget {
  final MatchModel match;
  final String distanceText;

  const MatchMarkerSheet({
    super.key,
    required this.match,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.coralSoft,
                backgroundImage: match.image != null && match.image!.isNotEmpty
                    ? CachedNetworkImageProvider(match.image!)
                    : null,
                child: match.image == null || match.image!.isEmpty
                    ? Text(
                        match.name.isNotEmpty ? match.name.substring(0, 1).toUpperCase() : 'M',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coral, fontSize: 22),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          match.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 6, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('Active', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.near_me_outlined, size: 14, color: AppColors.coral),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.coralDark),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '· ${match.city}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (match.bio.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '“${match.bio}”',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/chat/${match.id}', extra: match);
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Start Chat'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(callProvider.notifier).initiateCall(match, audioOnly: false);
                    context.push('/video-call');
                  },
                  icon: const Icon(Icons.videocam_outlined, size: 18),
                  label: const Text('Video Call'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

