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
import 'package:seshlly/features/dashboard/profile/presentation/screens/verify_id_screen.dart';
import 'package:seshlly/features/dashboard/profile/presentation/screens/verify_photo_screen.dart';
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
import '../features/dashboard/chat/presentation/bloc/strike_bloc.dart';
import '../features/strike/presentation/screen/pending_strikes_screen.dart';
import '../features/strike/presentation/screen/strike_view_screen.dart';
import '../features/auth/data/response_ml/register_response.dart' show BuddyStrike;
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
import '../features/feed_leaderboard/presentation/widgets/feed_stories.dart';
import '../core/services/monitoring_service.dart';
import '../features/gym_map/presentation/screens/gym_map_screen.dart';
import '../features/safety/presentation/screens/blocked_users_screen.dart';
import '../features/match/match_screen.dart';
import '../core/services/navigation_service.dart';

GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: NavigationService.navigatorKey,
    initialLocation: AppRoutes.splash,
    // Analytics screen_view events (no-op until Firebase is configured)
    observers: MonitoringService.instance.navigatorObservers,
    refreshListenable: GoRouterAuthNotifier(authBloc),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final status = authBloc.state.status;
      final walkthroughSeen = authBloc.state.user?.walkthroughSeen;

      debugPrint("status = $status");
      debugPrint("needsOnboarding = $walkthroughSeen");
      debugPrint("appCurrentLocation = $location");
      debugPrint("***********************");

      const authRoutes = [
        AppRoutes.welcome,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];

      final isAuthPage = authRoutes.contains(location);

      // 1. Loading
      if (status == AuthStatus.initial) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // 2. Not authenticated
      if (status == AuthStatus.unauthenticated) {
        return isAuthPage ? null : AppRoutes.welcome;
      }

      // 3. Authenticated but walkthrough required
      if ((status == AuthStatus.authenticated ||
              status == AuthStatus.onboarding) &&
          walkthroughSeen == false) {
        return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
      }

      // 4. Authenticated and walkthrough completed
      if (status == AuthStatus.authenticated && walkthroughSeen == true) {
        return (location == AppRoutes.onboarding ||
                location == AppRoutes.splash ||
                location == AppRoutes.welcome)
            ? AppRoutes.home
            : null;
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
          return MultiBlocProvider(
            providers: [
              BlocProvider<ChatBloc>(create: (_) => getIt<ChatBloc>()),
              BlocProvider<StrikeBloc>(create: (_) => getIt<StrikeBloc>()),
            ],

            child: ChatScreen(
              chatId: state.pathParameters['chatId']!,
              buddyId: extra?['buddyId'] ?? '',
              buddyName: extra?['buddyName'] ?? '',
              buddyAvatar: extra?['buddyAvatar'],
              matchId: extra?['matchId'], // pass matchId for Strike streak
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
              gymName: extra?['gymName'] as String?,
            ),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.uploadProof,
        // Without the session (e.g. deep link / app restart) go back to Sessions
        redirect: (context, state) =>
            state.extra is WorkoutSession ? null : AppRoutes.sessions,
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

      // Flash (Strike) — received flashes (constants existed, routes didn't)
      GoRoute(
        path: AppRoutes.pendingStrikes,
        builder: (context, state) => const PendingStrikesScreen(),
      ),
      GoRoute(
        path: AppRoutes.strikeView,
        redirect: (context, state) {
          final e = state.extra;
          return (e is Map && e['strike'] is BuddyStrike) ? null : AppRoutes.pendingStrikes;
        },
        builder: (context, state) {
          final e = state.extra as Map;
          return StrikeViewScreen(
            strike: e['strike'] as BuddyStrike,
            buddyName: e['buddyName'] as String? ?? 'Buddy',
            streak: e['streak'] as int? ?? 0,
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
          // Share Discover's bloc: liking here advances the same deck and
          // the match dialog works (a fresh bloc reloaded profiles + spinner)
          final shared = extra?['discoverBloc'];
          if (shared is DiscoverBloc) {
            return BlocProvider.value(
              value: shared,
              child: BuddyViewScreen(buddyProfile: extra?['buddyProfile']),
            );
          }
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

      // Influencer
      GoRoute(
        path: AppRoutes.verifyPhoto,
        builder: (_, __) => const VerifyPhotoScreen(),
      ),

      // Influencer
      GoRoute(
        path: AppRoutes.verifyId,
        builder: (_, __) => const VerifyIdScreen(),
      ),

      // ── Safety ───────────────────────────────────────
      GoRoute(
        path: AppRoutes.blockedUsers,
        builder: (_, __) => const BlockedUsersScreen(),
      ),
      // ── Gym map ──────────────────────────────────────
      GoRoute(
        path: AppRoutes.gymMap,
        builder: (_, __) => const GymMapScreen(),
      ),

      // ── Feed ─────────────────────────────────────────
      GoRoute(path: AppRoutes.feed, builder: (_, __) => const FeedScreen()),
      // Story viewer (feed as stories) — extra: {groups, index}
      GoRoute(
        path: AppRoutes.storyViewer,
        pageBuilder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? const {};
          final groups = (extra['groups'] as List?)?.cast<StoryGroup>() ?? const <StoryGroup>[];
          return CustomTransitionPage(
            key: state.pageKey,
            opaque: true,
            child: groups.isEmpty
                ? const FeedScreen()
                : StoryViewerScreen(
                    groups: groups,
                    initialIndex: extra['index'] as int? ?? 0,
                  ),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.0).animate(anim),
                child: child,
              ),
            ),
          );
        },
      ),

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
  static const storyViewer = '/stories';
  static const blockedUsers = '/settings/blocked';
  static const gymMap = '/gyms/map';

  // Strike 2 — Buddy Strike
  static const strikeView = '/strike/view';
  static const pendingStrikes = '/strikes/pending';
  static const forgotPassword = '/forgotPassword';

  // Influencer
  static const influencerApply = '/influencer/apply';
  static const influencerProfile = '/influencer/:id';

  static const verifyPhoto = '/verify/photo';
  static const verifyId = '/verify/id';

}
