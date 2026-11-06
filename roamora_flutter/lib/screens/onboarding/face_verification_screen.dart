import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/pookie_verified_badge.dart';
import '../../providers/auth_provider.dart';

class FaceVerificationScreen extends ConsumerStatefulWidget {
  final bool isFromOnboarding;

  const FaceVerificationScreen({
    super.key,
    this.isFromOnboarding = false,
  });

  @override
  ConsumerState<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends ConsumerState<FaceVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isInitializing = false;
  bool _isVerifying = false;
  String? _sessionId;
  String? _providerName;
  bool _providerConfigured = false;
  List<String> _requiredEnvVars = const [];
  String? _capturedSelfieBase64;
  String? _errorMessage;
  String? _providerNotice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLivenessSession();
    });
  }

  Future<void> _initializeLivenessSession() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });
    try {
      final res = await ref.read(authProvider.notifier).startLivenessSession();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _sessionId = res['sessionId'] as String?;
        _providerName = res['provider'] as String? ?? 'unconfigured';
        _providerConfigured = res['providerConfigured'] as bool? ?? false;
        _requiredEnvVars = (res['requiredEnvVars'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['FACETEC_SERVER_URL', 'FACETEC_DEVICE_KEY_IDENTIFIER'];
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        if (e.statusCode == 404) {
          _providerNotice =
              'Face Liveness endpoint is ready in the codebase. Deploy the updated backend to Render and configure FaceTec or Jumio API keys to enable live biometric verification.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _captureLiveSelfieAndVerify() async {
    setState(() {
      _errorMessage = null;
    });

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Camera permission is required for Face Liveness Verification. Please allow camera access in Settings.';
      });
      return;
    }

    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 720,
      maxHeight: 720,
      imageQuality: 80,
    );

    if (file == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Selfie capture was cancelled. Tap below when you are ready to try again.';
      });
      return;
    }

    final bytes = await file.readAsBytes();
    final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    setState(() {
      _capturedSelfieBase64 = base64Image;
      _isVerifying = true;
    });

    try {
      final sessionId = _sessionId ?? 'pending-session';
      final res = await ref.read(authProvider.notifier).verifyLiveness(
            sessionId: sessionId,
            faceScanPayload: base64Encode(bytes),
            auditTrailImage: base64Image,
          );
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
      });

      if (res['verified'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity verified! You earned the Pookie Verified badge.'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isVerified = user?.isIdentityVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Face Liveness Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isVerified
                              ? const Color(0xFFE8F5FE)
                              : AppColors.primaryPale,
                          border: Border.all(
                            color: isVerified
                                ? const Color(0xFF1D9BF0)
                                : AppColors.primary,
                            width: 3,
                          ),
                        ),
                        child: _capturedSelfieBase64 != null
                            ? ClipOval(
                                child: Image.memory(
                                  base64Decode(_capturedSelfieBase64!.split(',').last),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                isVerified
                                    ? Icons.verified_user_rounded
                                    : Icons.face_retouching_natural_rounded,
                                size: 52,
                                color: isVerified
                                    ? const Color(0xFF1D9BF0)
                                    : AppColors.primaryDark,
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (isVerified) ...[
                      const Center(child: PookieVerifiedBadge()),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      isVerified
                          ? 'Your Identity is Verified!'
                          : 'Earn Your Blue "Pookie Verified" Badge',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVerified
                          ? 'Your live 3D face scan has been verified. Your official blue Pookie Verified badge is active on your profile (+20% completion).'
                          : 'Complete a real-time 3D Face Liveness scan to prove you are a real human and unlock the final 20% of your Profile Completion score.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Checklist
                    _buildGuideRow(
                      Icons.wb_sunny_outlined,
                      'Face a well-lit area without harsh backlight',
                    ),
                    const SizedBox(height: 10),
                    _buildGuideRow(
                      Icons.visibility_outlined,
                      'Remove sunglasses, masks, or heavy hats',
                    ),
                    const SizedBox(height: 10),
                    _buildGuideRow(
                      Icons.security_rounded,
                      'Cryptographic liveness check via FaceTec / Jumio (never faked)',
                    ),
                    const SizedBox(height: 20),

                    if (_isInitializing)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    if (!_providerConfigured && !_isInitializing && !isVerified) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textPrimary),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Liveness Provider SDK Configuration Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _providerNotice ??
                                  'Provider: ${_providerName?.toUpperCase() ?? "UNCONFIGURED"}. To activate cryptographic biometric verification in production, configure ${_requiredEnvVars.join(", ")} in backend environment variables.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (!isVerified)
                      ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _captureLiveSelfieAndVerify,
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_front_rounded),
                        label: Text(
                          _isVerifying
                              ? 'Verifying Liveness Scan...'
                              : 'Start Live Selfie Scan',
                        ),
                      ),
                    const SizedBox(height: 12),

                    OutlinedButton(
                      onPressed: () {
                        if (widget.isFromOnboarding) {
                          context.go('/discover');
                        } else if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/profile');
                        }
                      },
                      child: Text(
                        widget.isFromOnboarding
                            ? (isVerified ? 'Enter Pookie Match →' : 'Skip for Now & Enter App (80% Complete)')
                            : 'Back to Profile',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
