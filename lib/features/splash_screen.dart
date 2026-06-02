import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:seshlly/routes/app_router.dart';

import '../core/services/secure_storage_service.dart';
import '../core/services/storage_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_theme.dart';
import '../di_injection/dependency_injection.dart';

// Pure UI — GoRouter redirect driven by AuthBloc handles navigation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    final token = await getIt<SecureStorageService>().getAccessToken();
    final isOnboarded = await getIt<StorageService>().getOnboarding();
    if (kDebugMode) {
      print("Token on _navigate: $token");
    }
    if (token != null && token.isNotEmpty && isOnboarded) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
    } else if (token != null && token.isNotEmpty && !isOnboarded) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go(AppRoutes.home);
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          context.go(AppRoutes.welcome);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGlow,
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'F',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        fontFamily: 'Syne',
                      ),
                    ),
                  ),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 20),
                Text('FitConnect', style: AppTextStyles.h1())
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.3),
                const SizedBox(height: 8),
                Text(
                  'Find Your Gym Buddy',
                  style: AppTextStyles.body(),
                ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 60),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    backgroundColor: AppColors.surface2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    minHeight: 3,
                  ),
                ).animate(delay: 600.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
