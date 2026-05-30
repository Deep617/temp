import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/features/auth/presentation/bloc/profile_bloc.dart';
import 'package:seshlly/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/register_screen.dart';
import 'package:seshlly/features/auth/presentation/screens/welcome_screen.dart';
import 'package:seshlly/features/splash_screen.dart';

import '../di_injection/dependency_injection.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/screens/login_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: AppRoutesPath.splash,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPath.welcome,
        builder: (context, state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutesPath.login,
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
        path: AppRoutesPath.register,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<AuthBloc>(),
            child: const RegisterScreen(),
          );
        },
      ),

      GoRoute(
        path: AppRoutesPath.onboarding,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => getIt<ProfileBloc>(),
            child: const OnboardingScreen(),
          );
        },
      ),
      /*     GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),*/
    ],
  );
}

class AppRoutesPath {
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
