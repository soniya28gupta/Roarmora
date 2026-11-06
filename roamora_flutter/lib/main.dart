import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'models/match_model.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/onboarding/onboarding_wizard_screen.dart';
import 'screens/onboarding/face_verification_screen.dart';
import 'screens/shell/main_navigation_shell.dart';
import 'screens/discover/discover_screen.dart';
import 'screens/map/adventure_map_screen.dart';
import 'screens/matches/matches_screen.dart';
import 'screens/matches/chat_screen.dart';
import 'screens/games/games_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/blocked_users_screen.dart';
import 'screens/calling/video_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[STARTUP] WidgetsFlutterBinding initialized.');

  try {
    debugPrint('[STARTUP] Initializing Firebase Core...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 3));
    debugPrint('[STARTUP] Firebase Core initialized.');
  } catch (e, stack) {
    debugPrint('[STARTUP Warning] Firebase init failed or timed out: $e\n$stack');
  }

  debugPrint('[STARTUP] Running app with ProviderScope...');
  runApp(
    const ProviderScope(
      child: RoamoraApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'];
        return LoginScreen(initialEmail: email);
      },
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final nextRoute = state.uri.queryParameters['next'] ?? '/onboarding';
        final preSent = state.uri.queryParameters['preSent'] == 'true';
        return OtpVerificationScreen(
          email: email,
          nextRoute: nextRoute,
          preSent: preSent,
        );
      },
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingWizardScreen(),
    ),
    GoRoute(
      path: '/face-verification',
      builder: (context, state) {
        final fromOnboarding = state.uri.queryParameters['onboarding'] == 'true';
        return FaceVerificationScreen(isFromOnboarding: fromOnboarding);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => MainNavigationShell(child: child),
      routes: [
        GoRoute(
          path: '/discover',
          builder: (context, state) => const DiscoverScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const AdventureMapScreen(),
        ),
        GoRoute(
          path: '/matches',
          builder: (context, state) => const MatchesScreen(),
        ),
        GoRoute(
          path: '/games',
          builder: (context, state) => const GamesScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/chat/:matchId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? '';
        final match = state.extra as MatchModel?;
        return ChatScreen(matchId: matchId, match: match);
      },
    ),
    GoRoute(
      path: '/video-call',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VideoCallScreen(),
    ),
    GoRoute(
      path: '/blocked-users',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BlockedUsersScreen(),
    ),
  ],
);

class RoamoraApp extends StatelessWidget {
  const RoamoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pookie Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}
