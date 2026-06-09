import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/register_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/welcome_screen.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_bloc.dart';
import 'package:seshlly/features/dashboard/profile/presentation/screens/edit_profile_screen.dart';
import 'package:seshlly/features/dashboard/session/presentation/bloc/session_bloc.dart';
import 'package:seshlly/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:seshlly/features/notification/presentation/screen/notifications_screen.dart';
import 'package:seshlly/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:seshlly/features/subscription/presentation/screen/subscription_screen.dart';
import 'package:seshlly/splash_screen.dart';

import '../di_injection/dependency_injection.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/discover/presentation/screens/discover_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/dashboard/profile/presentation/screens/buddy_profile_screen.dart';
import '../features/dashboard/profile/presentation/screens/profile_screen.dart';
import '../features/dashboard/session/presentation/screens/schedule_session_screen.dart';
import '../features/dashboard/session/presentation/screens/sessions_screen.dart';
import '../features/dashboard/session/presentation/screens/upload_proof_screen.dart';
import '../features/match/match_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutes.splash,
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
            child: const OnboardingScreen(),
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

      /*GoRoute(
        path: AppRoutes.chat,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(
            chatId:      state.pathParameters['chatId']!,
            buddyName:   extra?['buddyName']   ?? '',
            buddyAvatar: extra?['buddyAvatar'],
          );
        },
      ),*/
      GoRoute(
        path: AppRoutes.buddyProfile,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: BuddyProfileScreen(userId: state.pathParameters['userId']!),
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
          return BlocProvider(
            create: (_) => getIt<SessionBloc>(),
            child: UploadProofScreen(
              sessionId: state.pathParameters['sessionId']!,
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
          /* GoRoute(path: AppRoutesPath.chats,    builder: (_, __) => const ChatsListScreen()),*/
          GoRoute(
            path: AppRoutes.chats,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.sessions,
            builder: (context, state) => const SessionsScreen(),
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
                color: Color(0xFFBAEE0B),
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
}
