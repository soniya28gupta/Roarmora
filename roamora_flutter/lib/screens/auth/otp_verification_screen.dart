import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/pookie_brand_mark.dart';
import '../../providers/auth_provider.dart';

/// Keeps only digits (so pasted text such as "123 456" or "G-123456" works)
/// and limits the value to [length] characters, with the caret at the end.
class OtpDigitsFormatter extends TextInputFormatter {
  final int length;
  const OtpDigitsFormatter({this.length = 6});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > length) digits = digits.substring(0, length);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String nextRoute;
  final bool preSent;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.nextRoute = '/onboarding',
    this.preSent = false,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int otpExpirySeconds = 60;
  static const int otpLength = 6;

  // One real input drives the six visual boxes, so paste, Android autofill,
  // backspace and focus all behave consistently.
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  Timer? _countdownTimer;
  int _remainingSeconds = otpExpirySeconds;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _statusBanner;
  String? _errorText;
  bool _providerConfigured = true;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      if (mounted) setState(() {});
    });
    _otpFocus.addListener(() {
      if (mounted) setState(() {});
    });
    _startTimer();
    if (widget.preSent) {
      _statusBanner =
          'A 6-digit verification code has been sent to ${widget.email}. Valid for 60 seconds.';
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _dispatchOtp(initial: true);
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startTimer([int seconds = otpExpirySeconds]) {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = seconds;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        setState(() {
          _remainingSeconds = 0;
        });
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds -= 1;
        });
      }
    });
  }

  String get _enteredOtp => _otpController.text;

  Future<void> _dispatchOtp({bool initial = false}) async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _errorText = null;
      if (!initial) {
        _otpController.clear();
      }
    });

    try {
      final res = await ref.read(authProvider.notifier).sendOtp(widget.email);
      if (!mounted) return;
      final expires = (res['expiresInSeconds'] as int?) ?? otpExpirySeconds;
      final sent = res['sent'] as bool? ?? true;
      final message = res['message'] as String?;

      if (!sent) {
        setState(() {
          _isSending = false;
          _providerConfigured = false;
          _statusBanner = null;
          _errorText = message ?? 'Failed to deliver OTP to ${widget.email}.';
        });
        return;
      }

      _startTimer(expires);
      setState(() {
        _isSending = false;
        _providerConfigured = true;
        _errorText = null;
        _statusBanner = message ??
            'A 6-digit verification code has been sent to ${widget.email}. Valid for 60 seconds.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _statusBanner = null;
        _errorText = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _statusBanner = null;
        _errorText = e.toString();
      });
    }
  }

  Future<void> _verifyCode() async {
    final code = _enteredOtp;
    if (code.length != otpLength || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _errorText = 'Please enter all 6 numeric digits of your verification code.';
      });
      return;
    }

    if (_remainingSeconds <= 0) {
      setState(() {
        _errorText = 'This OTP has expired (60-second limit). Please tap Resend OTP.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    final ok = await ref.read(authProvider.notifier).verifyOtp(widget.email, code);
    if (!mounted) return;

    if (ok) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully!'),
          backgroundColor: AppColors.emerald,
        ),
      );
      final authState = ref.read(authProvider);
      final target = (authState.user?.onboardingCompleted ?? false)
          ? '/discover'
          : widget.nextRoute;
      context.go(target);
    } else {
      final authErr = ref.read(authProvider).error;
      setState(() {
        _isVerifying = false;
        _errorText = authErr ?? 'Invalid or expired verification code.';
      });
    }
  }

  String _formatCountdown(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  /// Six visual boxes sized from the available width, with a transparent
  /// [TextField] on top that receives typing, paste and autofill.
  Widget _buildOtpBoxes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 300 ? 6.0 : 8.0;
        final boxWidth =
            ((constraints.maxWidth - gap * (otpLength - 1)) / otpLength).clamp(0.0, 52.0);
        final boxHeight = (boxWidth * 1.2).clamp(40.0, 58.0);
        final fontSize = (boxWidth * 0.45).clamp(16.0, 22.0);
        final text = _otpController.text;
        final activeIndex = text.length.clamp(0, otpLength - 1);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _otpFocus.requestFocus(),
          child: SizedBox(
            height: boxHeight,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(otpLength, (index) {
                    final hasDigit = index < text.length;
                    final isActive = _otpFocus.hasFocus && index == activeIndex;
                    return Container(
                      width: boxWidth,
                      height: boxHeight,
                      margin: EdgeInsets.only(right: index == otpLength - 1 ? 0 : gap),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive ? AppColors.primary : AppColors.border,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        hasDigit ? text[index] : '',
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: TextField(
                    controller: _otpController,
                    focusNode: _otpFocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    autocorrect: false,
                    enableSuggestions: false,
                    showCursor: false,
                    maxLength: otpLength,
                    maxLines: 1,
                    expands: false,
                    inputFormatters: const [OtpDigitsFormatter(length: otpLength)],
                    style: const TextStyle(color: Colors.transparent, fontSize: 1),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) {
                      if (_enteredOtp.length == otpLength && !_isVerifying) _verifyCode();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remainingSeconds == 0 && !_isSending;
    final pillColor = _remainingSeconds > 10 ? AppColors.primaryDark : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
            }
          },
        ),
        title: const Text('6-Digit OTP Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.cardShadow,
                ),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: PookieBrandMark(size: 46)),
                      const SizedBox(height: 16),
                      Text(
                        'Verify Your Email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit security code sent to\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),

                      // 60-Second Countdown Pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _remainingSeconds > 10
                                ? AppColors.primaryPale
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _remainingSeconds > 10
                                  ? AppColors.primary.withValues(alpha: 0.35)
                                  : AppColors.error.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_outlined, size: 16, color: pillColor),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _remainingSeconds > 0
                                      ? 'Code expires in ${_formatCountdown(_remainingSeconds)}'
                                      : 'Code expired (60s limit reached)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: pillColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6 OTP boxes (paste / autofill / manual entry / backspace)
                      _buildOtpBoxes(),
                      const SizedBox(height: 20),

                      if (_statusBanner != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _providerConfigured
                                ? AppColors.emeraldPale
                                : AppColors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _statusBanner!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _providerConfigured
                                  ? AppColors.emerald
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (_errorText != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                          ),
                          child: Text(
                            _errorText!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      ElevatedButton(
                        onPressed: (_isVerifying || _enteredOtp.length < otpLength)
                            ? null
                            : _verifyCode,
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Verify 6-Digit Code'),
                      ),
                      const SizedBox(height: 14),

                      OutlinedButton.icon(
                        onPressed: canResend ? () => _dispatchOtp(initial: false) : null,
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(
                          canResend ? 'Resend OTP' : 'Resend OTP in ${_remainingSeconds}s',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go(widget.nextRoute),
                        child: const Text(
                          'Continue to Onboarding Setup →',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
