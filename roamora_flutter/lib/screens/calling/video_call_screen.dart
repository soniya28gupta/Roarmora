import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/call_provider.dart';
import 'match_switcher_sheet.dart';

class VideoCallScreen extends ConsumerWidget {
  const VideoCallScreen({super.key});

  String _formatDuration(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callProvider);
    final callNotifier = ref.read(callProvider.notifier);
    final match = callState.currentMatch;

    // Auto-pop when call ends
    ref.listen<CallState>(callProvider, (previous, next) {
      if ((previous?.status == CallStatus.connected || previous?.status == CallStatus.calling) &&
          (next.status == CallStatus.idle || next.status == CallStatus.ended)) {
        if (context.mounted && context.canPop()) {
          context.pop();
        }
      }
    });

    final matchName = match?.name ?? 'Roamora Match';
    final matchImage = match?.image;

    return Scaffold(
      backgroundColor: AppColors.callBackground,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Remote Video Stream or Avatar Screen
            Positioned.fill(
              child: callState.status == CallStatus.connected && !callState.isAudioOnly
                  ? RTCVideoView(
                      callNotifier.remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : _buildAvatarStage(matchName, matchImage, callState),
            ),

            // 2. Radar Matchmaking / Queueing Overlay (Feature 12)
            if (callState.status == CallStatus.skipping)
              Positioned.fill(
                child: Container(
                  color: AppColors.callBackground.withOpacity(0.92),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.coral, width: 2),
                            color: AppColors.coral.withOpacity(0.15),
                          ),
                          child: const Center(
                            child: Icon(Icons.radar, color: AppColors.coral, size: 40),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Radar Queue Matchmaking',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            callState.noticeMessage ?? 'Finding next eligible mutual match…',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Top Call Header (Name, Duration, Privacy Badge)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.coralLight, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          matchName,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (callState.status == CallStatus.connected) ...[
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white38, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            _formatDuration(callState.callDurationSeconds),
                            style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Close / Minimize
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black45),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => callNotifier.endCall(),
                  ),
                ],
              ),
            ),

            // 4. Local Camera Preview (Picture-in-Picture)
            if (!callState.isAudioOnly && callState.status != CallStatus.skipping)
              Positioned(
                top: 70,
                right: 16,
                width: 110,
                height: 155,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white30, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: callState.isCameraOff
                      ? Container(
                          color: AppColors.callSurface,
                          child: const Center(
                            child: Icon(Icons.videocam_off, color: Colors.white38, size: 28),
                          ),
                        )
                      : RTCVideoView(
                          callNotifier.localRenderer,
                          mirror: callState.isFrontCamera,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                ),
              ),

            // 5. Call Control Actions Bar (Bottom)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.callSurface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.callBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mic Mute
                    IconButton(
                      icon: Icon(
                        callState.isMicMuted ? Icons.mic_off : Icons.mic,
                        color: callState.isMicMuted ? AppColors.error : Colors.white,
                      ),
                      onPressed: () => callNotifier.toggleMic(),
                      tooltip: callState.isMicMuted ? 'Unmute' : 'Mute',
                    ),

                    // Camera On/Off
                    if (!callState.isAudioOnly)
                      IconButton(
                        icon: Icon(
                          callState.isCameraOff ? Icons.videocam_off : Icons.videocam,
                          color: callState.isCameraOff ? AppColors.error : Colors.white,
                        ),
                        onPressed: () => callNotifier.toggleCamera(),
                        tooltip: callState.isCameraOff ? 'Turn Camera On' : 'Turn Camera Off',
                      ),

                    // Camera Flip (Front/Back)
                    if (!callState.isAudioOnly)
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                        onPressed: () => callNotifier.flipCamera(),
                        tooltip: 'Flip Camera',
                      ),

                    // FEATURE 11: Match Switcher
                    IconButton(
                      icon: const Icon(Icons.swap_horiz, color: AppColors.coralLight),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => MatchSwitcherSheet(
                            currentMatchId: match?.id ?? '',
                          ),
                        );
                      },
                      tooltip: 'Switch Match',
                    ),

                    // FEATURE 12: Skip to Next Match
                    InkWell(
                      onTap: () => callNotifier.skipToNextMatch(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.skip_next, color: AppColors.warning, size: 26),
                      ),
                    ),

                    // End Call
                    InkWell(
                      onTap: () => callNotifier.endCall(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStage(String name, String? image, CallState callState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.coralGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.coral.withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.callSurface,
              backgroundImage: image != null && image.isNotEmpty ? CachedNetworkImageProvider(image) : null,
              child: image == null || image.isEmpty
                  ? Text(
                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'M',
                      style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            callState.status == CallStatus.calling
                ? 'Ringing your match’s device…'
                : callState.status == CallStatus.connected
                    ? 'Voice connected'
                    : 'Connecting call…',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

