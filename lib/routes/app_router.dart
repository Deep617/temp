import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/register_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/welcome_screen.dart';
import 'package:seshlly/features/dashboard/profile/presentation/bloc/profile_bloc.dart';
import 'package:seshlly/features/splash_screen.dart';

import '../di_injection/dependency_injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/discover/presentation/screens/discover_screen.dart';
import '../features/dashboard/home_screen.dart';
import '../features/dashboard/profile/presentation/screens/profile_screen.dart';
import '../features/dashboard/session/presentation/screens/sessions_screen.dart';

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
        builder: (context, state) {
          print("login route opened");
          return BlocProvider(
            create: (_) {
              print("AuthBloc created");
              return getIt<AuthBloc>();
            },

            child: const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<AuthBloc>(),
            child: const RegisterScreen(),
          );
        },
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
          /* GoRoute(path: AppRoutesPath.chats,    builder: (_, __) => const ChatsListScreen()),
          GoRoute(path: AppRoutesPath.sessions, builder: (_, __) => const SessionsScreen()),*/
          GoRoute(
            path: AppRoutes.chats,
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.sessions,
            builder: (_, __) => const SessionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
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
              'Page not found: \${state.uri}',
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
