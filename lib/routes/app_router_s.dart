// ─────────────────────────────────────────────────────────
//  AppRouter — V2 updated
//  lib/presentation/navigation/app_router.dart
//
//  Added V2 routes:
//   /challenges           → ChallengesScreen
//   /challenges/:id       → ChallengeDetailScreen
// ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/dashboard/challanges/presentation/screen/challenge_detail_screen.dart';
import '../features/dashboard/challanges/presentation/screen/challenges_screen.dart';
import '../features/dashboard/challanges/presentation/screen/global_leaderboard_screen.dart';
import '../features/dashboard/chat/presentation/screen/chat_screen.dart';
import '../features/dashboard/chat/presentation/screen/chats_list_screen.dart';
import '../features/dashboard/discover/presentation/screens/discover_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/dashboard/profile/presentation/screens/buddy_profile_screen.dart';
import '../features/dashboard/profile/presentation/screens/edit_profile_screen.dart';
import '../features/dashboard/profile/presentation/screens/profile_screen.dart';
import '../features/dashboard/session/presentation/screens/schedule_session_screen.dart';
import '../features/dashboard/session/presentation/screens/sessions_screen.dart';
import '../features/dashboard/session/presentation/screens/upload_proof_screen.dart';
import '../features/match/match_screen.dart';
import '../features/notification/presentation/screen/notifications_screen.dart';
import '../features/subscription/presentation/screen/subscription_screen.dart';
import '../splash_screen.dart';

// V2

class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const discover = '/discover';
  static const match = '/match/:userId';
  static const chats = '/chats';
  static const chat = '/chat/:chatId';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const buddyProfile = '/buddy/:userId';
  static const sessions = '/sessions';
  static const scheduleSession = '/sessions/schedule';
  static const uploadProof = '/sessions/:sessionId/proof';
  static const subscription = '/subscription';
  static const notifications = '/notifications';

  // V2
  static const challenges = '/challenges';
  static const challengeDetail = '/challenges/:challengeId';
  static const globalLeaderboard = '/leaderboard/global';
}

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterAuthNotifier(authBloc),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoading =
          authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isOnboarding = authState.status == AuthStatus.onboarding;
      final isUnauthenticated = authState.status == AuthStatus.unauthenticated;

      final authRoutes = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.splash,
      ];
      final isOnAuthPage = authRoutes.contains(state.matchedLocation);

      if (isLoading) {
        return state.matchedLocation == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }

      // If authenticated but profile not set up — show onboarding
      // Check backend data (primaryActivity) not just SharedPreferences
      // This handles: new device, reinstall, first login
      final needsOnboarding =
          isOnboarding ||
          (isAuthenticated &&
              authState.user != null &&
              (authState.user!.primaryActivity == null ||
                  authState.user!.primaryActivity!.isEmpty));

      if (needsOnboarding && state.matchedLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (isUnauthenticated && !isOnAuthPage) return AppRoutes.welcome;

      if ((isAuthenticated || isOnboarding) && isOnAuthPage)
        return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Full-screen routes
      GoRoute(
        path: AppRoutes.challengeDetail,
        builder: (ctx, state) => ChallengeDetailScreen(
          challengeId: state.pathParameters['challengeId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.globalLeaderboard,
        builder: (_, __) => const GlobalLeaderboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.match,
        builder: (ctx, state) =>
            MatchScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            chatId: state.pathParameters['chatId']!,
            buddyName: extra?['buddyName'] ?? '',
            buddyId: extra?['buddyId'] ?? '',
            buddyAvatar: extra?['buddyAvatar'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.buddyProfile,
        builder: (ctx, state) => BuddyProfileScreen(
          userId: state.pathParameters['userId']!,
          buddyId: 'fdfsdfdsfd',
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.scheduleSession,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ScheduleSessionScreen(
            buddyId: extra?['buddyId'] ?? '',
            buddyName: extra?['buddyName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.uploadProof,
        builder: (ctx, state) =>
            UploadProofScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (_, __) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      // Shell — 5-tab bottom nav (V2 adds Challenges)
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.discover,
            builder: (_, __) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.chats,
            builder: (_, __) => const ChatsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.sessions,
            builder: (_, __) => const SessionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.challenges,
            builder: (_, __) => const ChallengesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '404',
              style: AppTextStyles.h1().copyWith(
                fontSize: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page not found: ${state.uri}',
              style: AppTextStyles.body(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ctx.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

class GoRouterAuthNotifier extends ChangeNotifier {
  GoRouterAuthNotifier(AuthBloc authBloc) {
    _subscription = authBloc.stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
