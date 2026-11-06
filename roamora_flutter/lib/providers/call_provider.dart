import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/call_session_model.dart';
import '../models/match_model.dart';

enum CallStatus {
  idle,
  initiating,
  calling,
  incomingRinging,
  connected,
  skipping,
  ended,
}

class CallState {
  final CallStatus status;
  final CallSessionModel? activeSession;
  final MatchModel? currentMatch;
  final bool isAudioOnly;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isFrontCamera;
  final int callDurationSeconds;
  final String? noticeMessage;
  final String? errorMessage;

  CallState({
    this.status = CallStatus.idle,
    this.activeSession,
    this.currentMatch,
    this.isAudioOnly = false,
    this.isMicMuted = false,
    this.isCameraOff = false,
    this.isFrontCamera = true,
    this.callDurationSeconds = 0,
    this.noticeMessage,
    this.errorMessage,
  });

  CallState copyWith({
    CallStatus? status,
    CallSessionModel? activeSession,
    MatchModel? currentMatch,
    bool? isAudioOnly,
    bool? isMicMuted,
    bool? isCameraOff,
    bool? isFrontCamera,
    int? callDurationSeconds,
    String? noticeMessage,
    String? errorMessage,
    bool clearNotice = false,
    bool clearError = false,
    bool clearSession = false,
  }) {
    return CallState(
      status: status ?? this.status,
      activeSession: clearSession ? null : (activeSession ?? this.activeSession),
      currentMatch: clearSession ? null : (currentMatch ?? this.currentMatch),
      isAudioOnly: isAudioOnly ?? this.isAudioOnly,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      callDurationSeconds: callDurationSeconds ?? this.callDurationSeconds,
      noticeMessage: clearNotice ? null : (noticeMessage ?? this.noticeMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class CallNotifier extends StateNotifier<CallState> {
  final ApiClient _api = ApiClient.instance;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  RTCVideoRenderer localRenderer = RTCVideoRenderer();
  RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  Timer? _pollingTimer;
  Timer? _durationTimer;
  int _lastCandidateTimestamp = 0;

  CallNotifier() : super(CallState()) {
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
  }

  // WebRTC ICE configuration
  final Map<String, dynamic> _rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Future<MediaStream?> _startLocalMedia({bool audioOnly = false}) async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': audioOnly
            ? false
            : {
                'facingMode': state.isFrontCamera ? 'user' : 'environment',
                'width': {'ideal': 1280},
                'height': {'ideal': 720},
              },
      };

      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      localRenderer.srcObject = stream;
      return stream;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Camera/Microphone permission denied: $e');
      return null;
    }
  }

  // 1. Initiate outbound call
  Future<void> initiateCall(MatchModel match, {bool audioOnly = false}) async {
    await _cleanupPeerConnection();
    state = state.copyWith(
      status: CallStatus.calling,
      currentMatch: match,
      isAudioOnly: audioOnly,
      callDurationSeconds: 0,
      clearError: true,
    );

    final stream = await _startLocalMedia(audioOnly: audioOnly);
    if (stream == null) {
      state = state.copyWith(status: CallStatus.idle);
      return;
    }

    try {
      final pc = await createPeerConnection(_rtcConfig);
      _peerConnection = pc;

      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }

      pc.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams[0];
          state = state.copyWith(status: CallStatus.connected);
          _startDurationTimer();
        }
      };

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      final targetUserId = match.otherUserId ?? match.id;
      final res = await _api.post(
        ApiEndpoints.callInitiate,
        data: {
          'targetUserId': targetUserId,
          'matchId': match.id,
          'callType': audioOnly ? 'AUDIO' : 'VIDEO',
          'offer': offer.toMap(),
        },
      );

      final session = CallSessionModel.fromJson(res as Map<String, dynamic>);
      state = state.copyWith(activeSession: session);
      _lastCandidateTimestamp = DateTime.now().millisecondsSinceEpoch;

      pc.onIceCandidate = (candidate) {
        if (session.id.isNotEmpty) {
          _api.post(
            ApiEndpoints.callCandidate(session.id),
            data: {'candidate': candidate.toMap()},
          ).catchError((_) {});
        }
      };

      _startCandidatePolling(session.id);
    } catch (e) {
      state = state.copyWith(status: CallStatus.ended, errorMessage: e.toString());
      await endCall();
    }
  }

  // 2. Accept incoming call
  Future<void> acceptCall(CallSessionModel session, MatchModel match) async {
    await _cleanupPeerConnection();
    final isAudio = session.callType == 'AUDIO';
    state = state.copyWith(
      status: CallStatus.connected,
      activeSession: session,
      currentMatch: match,
      isAudioOnly: isAudio,
      callDurationSeconds: 0,
      clearError: true,
    );

    final stream = await _startLocalMedia(audioOnly: isAudio);
    if (stream == null) {
      state = state.copyWith(status: CallStatus.idle);
      return;
    }

    try {
      final pc = await createPeerConnection(_rtcConfig);
      _peerConnection = pc;

      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }

      pc.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams[0];
        }
      };

      if (session.offer != null) {
        await pc.setRemoteDescription(
          RTCSessionDescription(
            session.offer!['sdp'] as String? ?? '',
            session.offer!['type'] as String? ?? 'offer',
          ),
        );

        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);

        await _api.post(
          ApiEndpoints.callAnswer(session.id),
          data: {'answer': answer.toMap()},
        );
      }

      _lastCandidateTimestamp = DateTime.now().millisecondsSinceEpoch;

      pc.onIceCandidate = (candidate) {
        if (session.id.isNotEmpty) {
          _api.post(
            ApiEndpoints.callCandidate(session.id),
            data: {'candidate': candidate.toMap()},
          ).catchError((_) {});
        }
      };

      _startCandidatePolling(session.id);
      _startDurationTimer();
    } catch (e) {
      state = state.copyWith(status: CallStatus.ended, errorMessage: e.toString());
      await endCall();
    }
  }

  // 3. Continuous ICE candidate and answer polling loop
  void _startCandidatePolling(String callId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
      try {
        final res = await _api.get(
          '${ApiEndpoints.callCandidates(callId)}?since=$_lastCandidateTimestamp',
        );

        if (res is Map<String, dynamic>) {
          final status = res['status'] as String?;
          if (status == 'ENDED' || status == 'SKIPPED' || status == 'DECLINED') {
            await endCall();
            return;
          }

          final pc = _peerConnection;
          if (pc == null) return;

          // If answer arrived for caller
          final currentRemoteDesc = await pc.getRemoteDescription();
          if (res['answer'] != null && currentRemoteDesc == null) {
            final answerMap = res['answer'] as Map<String, dynamic>;
            await pc.setRemoteDescription(
              RTCSessionDescription(
                answerMap['sdp'] as String? ?? '',
                answerMap['type'] as String? ?? 'answer',
              ),
            );
            state = state.copyWith(status: CallStatus.connected);
            _startDurationTimer();
          }

          // Trickle remote ICE candidates
          final candidates = res['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            for (final c in candidates) {
              if (c is Map && c['candidate'] != null) {
                final candData = c['candidate'] as Map<String, dynamic>;
                try {
                  await pc.addCandidate(
                    RTCIceCandidate(
                      candData['candidate'] as String?,
                      candData['sdpMid'] as String?,
                      candData['sdpMLineIndex'] as int?,
                    ),
                  );
                } catch (_) {}
              }
            }
            _lastCandidateTimestamp = DateTime.now().millisecondsSinceEpoch;
          }
        }
      } catch (_) {}
    });
  }

  // 4. Feature 11: Match Switcher — Switch to another eligible match in real time
  Future<void> switchToMatch(MatchModel newMatch) async {
    final currentSession = state.activeSession;
    state = state.copyWith(
      status: CallStatus.skipping,
      noticeMessage: 'Switching call to ${newMatch.name}...',
    );

    // End old call cleanly
    if (currentSession != null) {
      try {
        await _api.post(ApiEndpoints.callEnd(currentSession.id));
      } catch (_) {}
    }
    await _cleanupPeerConnection();

    // Initiate new call to selected match
    await Future.delayed(const Duration(milliseconds: 400));
    await initiateCall(newMatch, audioOnly: state.isAudioOnly);
  }

  // 5. Feature 12: Skip-to-Next Available Match in Queue
  Future<void> skipToNextMatch() async {
    final currentSession = state.activeSession;
    if (currentSession == null) return;

    state = state.copyWith(
      status: CallStatus.skipping,
      noticeMessage: 'Radar matchmaking: Finding next eligible match...',
    );

    await _cleanupPeerConnection();

    try {
      final res = await _api.post(ApiEndpoints.callSkipAndMatch(currentSession.id));
      if (res is Map<String, dynamic>) {
        if (res['found'] == true && res['nextMatch'] != null) {
          final nextMatch = MatchModel.fromJson(res['nextMatch'] as Map<String, dynamic>);
          state = state.copyWith(noticeMessage: 'Matched with ${nextMatch.name}! Connecting...');
          await Future.delayed(const Duration(milliseconds: 500));
          await initiateCall(nextMatch, audioOnly: state.isAudioOnly);
        } else {
          state = state.copyWith(
            status: CallStatus.ended,
            noticeMessage: res['message'] as String? ?? 'No other matches available right now.',
          );
        }
      }
    } catch (e) {
      state = state.copyWith(status: CallStatus.ended, errorMessage: e.toString());
    }
  }

  // 6. Media Toggles & Camera Flip
  void toggleMic() {
    if (_localStream == null) return;
    final audioTrack = _localStream!.getAudioTracks().isNotEmpty ? _localStream!.getAudioTracks()[0] : null;
    if (audioTrack != null) {
      final nextState = !state.isMicMuted;
      audioTrack.enabled = !nextState;
      state = state.copyWith(isMicMuted: nextState);
    }
  }

  void toggleCamera() {
    if (_localStream == null || state.isAudioOnly) return;
    final videoTrack = _localStream!.getVideoTracks().isNotEmpty ? _localStream!.getVideoTracks()[0] : null;
    if (videoTrack != null) {
      final nextState = !state.isCameraOff;
      videoTrack.enabled = !nextState;
      state = state.copyWith(isCameraOff: nextState);
    }
  }

  Future<void> flipCamera() async {
    if (_localStream == null || state.isAudioOnly) return;
    final videoTrack = _localStream!.getVideoTracks().isNotEmpty ? _localStream!.getVideoTracks()[0] : null;
    if (videoTrack != null) {
      await Helper.switchCamera(videoTrack);
      state = state.copyWith(isFrontCamera: !state.isFrontCamera);
    }
  }

  // 7. End Call cleanly
  Future<void> endCall() async {
    final session = state.activeSession;
    if (session != null) {
      try {
        await _api.post(ApiEndpoints.callEnd(session.id));
      } catch (_) {}
    }
    await _cleanupPeerConnection();
    state = state.copyWith(
      status: CallStatus.ended,
      clearSession: true,
      callDurationSeconds: 0,
    );
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(status: CallStatus.idle);
  }

  Future<void> declineCall(String callId) async {
    try {
      await _api.post(ApiEndpoints.callDecline(callId));
    } catch (_) {}
    await _cleanupPeerConnection();
    state = state.copyWith(status: CallStatus.idle, clearSession: true);
  }

  Future<void> _cleanupPeerConnection() async {
    _pollingTimer?.cancel();
    _durationTimer?.cancel();
    _pollingTimer = null;
    _durationTimer = null;

    if (_localStream != null) {
      for (final t in _localStream!.getTracks()) {
        await t.stop();
      }
      await _localStream!.dispose();
      _localStream = null;
    }

    if (_peerConnection != null) {
      await _peerConnection!.close();
      await _peerConnection!.dispose();
      _peerConnection = null;
    }

    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(callDurationSeconds: state.callDurationSeconds + 1);
    });
  }

  @override
  void dispose() {
    _cleanupPeerConnection();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }
}

final callProvider = StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier();
});
