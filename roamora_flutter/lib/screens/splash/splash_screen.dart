import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      debugPrint('[STARTUP] SplashScreen waiting minimum animation duration (1400ms)...');
      final splashDelay = Future.delayed(const Duration(milliseconds: 1400));
      final authFuture = ref.read(authProvider.notifier).checkAuth();

      // Concurrently await animation and auth validation with an absolute 5s safety ceiling
      await Future.wait([splashDelay, authFuture]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[STARTUP Warning] Splash timeout reached (5s). Continuing with current state.');
          return [];
        },
      );

      if (!mounted) return;

      final authState = ref.read(authProvider);
      debugPrint('[STARTUP] Deciding route: isAuthenticated=${authState.isAuthenticated}, '
          'onboardingCompleted=${authState.user?.onboardingCompleted}');

      if (authState.isAuthenticated && authState.user != null) {
        if (authState.user!.onboardingCompleted == false) {
          debugPrint('[STARTUP] Navigating -> /onboarding');
          context.go('/onboarding');
        } else {
          debugPrint('[STARTUP] Navigating -> /discover');
          context.go('/discover');
        }
      } else {
        debugPrint('[STARTUP] Navigating -> /login');
        context.go('/login');
      }
    } catch (e, stack) {
      debugPrint('[STARTUP Error] Error in SplashScreen._checkSession: $e\n$stack');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppColors.coralGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                    bottomLeft: Radius.circular(10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.coral.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '✨',
                    style: TextStyle(fontSize: 44),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pookie Match',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '.',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.coral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.coralSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.coral.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💖 '),
                  Text(
                    'Gamified Dating & Real-World Quests',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.coralDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.coral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

