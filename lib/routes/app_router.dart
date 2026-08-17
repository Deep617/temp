import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/onboarding_screen_s.dart';
import 'package:seshlly/features/auth/presentation/screens/register_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/welcome_screen.dart';
import 'package:seshlly/features/dashboard/chat/presentation/bloc/chat_bloc.dart';
import 'package:seshlly/features/dashboard/discover/presentation/screens/buddy_view_screen.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_bloc.dart';
import 'package:seshlly/features/dashboard/profile/presentation/screens/edit_profile_screen.dart';
import 'package:seshlly/features/dashboard/session/presentation/bloc/session_bloc.dart';
import 'package:seshlly/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:seshlly/features/notification/presentation/screen/notifications_screen.dart';
import 'package:seshlly/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:seshlly/features/subscription/presentation/screen/subscription_screen.dart';
import 'package:seshlly/splash_screen.dart';

import '../di_injection/dependency_injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/screens/influencer_apply_screen.dart';
import '../features/auth/presentation/screens/influencer_profile_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/challanges/presentation/bloc/challenge_bloc.dart';
import '../features/dashboard/challanges/presentation/screen/challenge_detail_screen.dart';
import '../features/dashboard/challanges/presentation/screen/challenges_screen.dart';
import '../features/dashboard/challanges/presentation/screen/global_leaderboard_screen.dart';
import '../features/dashboard/chat/presentation/screen/chat_screen.dart';
import '../features/dashboard/chat/presentation/screen/chats_list_screen.dart';
import '../features/dashboard/discover/presentation/bloc/discover_bloc.dart';
import '../features/dashboard/discover/presentation/screens/discover_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/dashboard/profile/presentation/screens/buddy_profile_screen.dart';
import '../features/dashboard/profile/presentation/screens/profile_screen.dart';
import '../features/dashboard/session/data/response_ml/workout_session.dart';
import '../features/dashboard/session/presentation/screens/schedule_session_screen.dart';
import '../features/dashboard/session/presentation/screens/sessions_screen.dart';
import '../features/dashboard/session/presentation/screens/upload_proof_screen.dart';
import '../features/feed_leaderboard/presentation/screen/feed_screen.dart';
import '../features/feed_leaderboard/presentation/screen/leaderboard_screen.dart';
import '../features/match/match_screen.dart';

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterAuthNotifier(authBloc),
    redirect: (context, state) async {
      final appCurrentLocation = state.matchedLocation;
      final authState = authBloc.state;
      final isUserLoading = authState.status == AuthStatus.initial;
      final isUserAuthenticated = authState.status == AuthStatus.authenticated;
      final isUserOnboarding = authState.status == AuthStatus.onboarding;
      final isUserUnauthenticated =
          authState.status == AuthStatus.unauthenticated;

      // Read from storage
      // final hasSeenWalkthrough = getIt<StorageService>().getWalkThrogh();

      final authRoutes = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.splash,
        AppRoutes.forgotPassword,
      ];
      final isOnAuthPage = authRoutes.contains(appCurrentLocation);

      if (isUserLoading) {
        return appCurrentLocation == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // If authenticated but profile not set up — show onboarding
      // Check backend data (primaryActivity) not just SharedPreferences
      // This handles: new device, reinstall, first login
      final needsOnboarding =
          isUserOnboarding ||
          (isUserAuthenticated &&
              authState.user != null &&
              (authState.user!.primaryActivity == null ||
                  authState.user!.primaryActivity!.isEmpty));

      if (needsOnboarding && appCurrentLocation != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }

      // Walkthrough (only once)
      /* if (isAuthenticated &&
          hasSeenWalkthrough == false &&
          appCurrentLocation != AppRoutes.walkthroughOverlay) {
        return AppRoutes.walkthroughOverlay;
      }*/

      debugPrint("status = ${authState.status}");
      debugPrint("needsOnboarding = $needsOnboarding");
      debugPrint("appCurrentLocation = $appCurrentLocation");
      debugPrint("***********************");

      if (isUserUnauthenticated && !isOnAuthPage) return AppRoutes.welcome;

      if (isUserAuthenticated &&
          !needsOnboarding &&
          (appCurrentLocation == AppRoutes.onboarding ||
              appCurrentLocation == AppRoutes.splash)) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: const OnboardingScreenS(),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.match,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: MatchScreen(userId: state.pathParameters['userId']!),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.chat,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => getIt<ChatBloc>(),
            child: ChatScreen(
              chatId: state.pathParameters['chatId']!,
              buddyId: extra?['buddyId'] ?? '',
              buddyName: extra?['buddyName'] ?? '',
              buddyAvatar: extra?['buddyAvatar'],
              matchId:     extra?['matchId'],    // pass matchId for Strike streak
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.buddyProfile,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: BuddyProfileScreen(
              userId: state.pathParameters['userId']!,
              chatId: extra?['chatId'] ?? '',
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: EditProfileScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.scheduleSession,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => getIt<SessionBloc>(),
            child: ScheduleSessionScreen(
              buddyId: extra?['buddyId'] ?? '',
              buddyName: extra?['buddyName'] ?? '',
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.uploadProof,
        builder: (context, state) {
          final extra = state.extra as WorkoutSession;
          return BlocProvider(
            create: (_) => getIt<SessionBloc>(),
            child: UploadProofScreen(
              sessionId: state.pathParameters['sessionId']!,
              session: extra,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<NotificationBloc>(),
            child: const NotificationsScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<SubscriptionBloc>(),
            child: const SubscriptionScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.buddyView,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => getIt<DiscoverBloc>(),
            child: BuddyViewScreen(buddyProfile: extra?['buddyProfile']),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.challengeDetail,
        builder: (ctx, state) {
          return BlocProvider(
            create: (_) => getIt<ChallengeBloc>(),
            child: ChallengeDetailScreen(
              challengeId: state.pathParameters['challengeId']!,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.globalLeaderboard,
        builder: (_, __) => const GlobalLeaderboardScreen(),
      ),

      // ── Leaderboard ───────────────────────────────────
      GoRoute(
        path: AppRoutes.leaderboard,
        builder: (_, __) => const LeaderboardScreen(),
      ),

      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),

      // Influencer
      GoRoute(
        path: AppRoutes.influencerApply,
        builder: (_, __) => const InfluencerApplyScreen(),
      ),
      GoRoute(
        path: AppRoutes.influencerProfile,
        builder: (ctx, state) =>
            InfluencerProfileScreen(influencerId: state.pathParameters['id']!),
      ),
      // ── Feed ─────────────────────────────────────────
      GoRoute(path: AppRoutes.feed, builder: (_, __) => const FeedScreen()),

      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.discover,
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: AppRoutes.chats,
            builder: (context, state) => const ChatsListScreen(),
          ),
          GoRoute(
            path: AppRoutes.sessions,
            builder: (context, state) => const SessionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.challenges,
            builder: (_, __) => const ChallengesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0D08),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(
                fontSize: 64,
                color: Color(0xFF0A84FF),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Page not found: ${state.uri}',
              style: const TextStyle(color: Color(0xFF8F9870)),
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

// ── Bridges GoRouter refresh with AuthBloc stream ─────────
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
  static const buddyView = '/buddy_view';

  // V2
  static const challenges = '/challenges';
  static const challengeDetail = '/challenges/:challengeId';
  static const globalLeaderboard = '/leaderboard/global';
  static const walkthroughOverlay = '/walkthroughOverlay';

  // New: Leaderboard + Feed
  static const leaderboard = '/leaderboard';
  static const feed = '/feed';

  // Strike 2 — Buddy Strike
  static const strikeView = '/strike/view';
  static const pendingStrikes = '/strikes/pending';
  static const forgotPassword = '/forgotPassword';

  // Influencer
  static const influencerApply = '/influencer/apply';
  static const influencerProfile = '/influencer/:id';
}
