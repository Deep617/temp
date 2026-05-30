// ═══════════════════════════════════════════════════════
//  welcome_screen.dart
// ═══════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:new_arch/routes/app_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/common/common_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.0,
                colors: [AppColors.primary.withOpacity(0.08), AppColors.bg],
              ),
            ),
          ),

          // Grid overlay
          Opacity(
            opacity: 0.08,
            child: GridPaper(
              color: AppColors.border,
              divisions: 2,
              subdivisions: 1,
              interval: 48,
              child: const SizedBox.expand(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppColors.primaryGlow, blurRadius: 20)],
                    ),
                    child: const Center(child: Text('F',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black))),
                  ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

                  const Spacer(),

                  // Hero text
                  Text('Find Your', style: AppTextStyles.display())
                      .animate(delay: 100.ms).fadeIn(duration: 400.ms).slideX(begin: -0.2),
                  Text('Gym Buddy.', style: AppTextStyles.display(color: AppColors.primary))
                      .animate(delay: 200.ms).fadeIn(duration: 400.ms).slideX(begin: -0.2),

                  const SizedBox(height: 20),

                  Text(
                    'Match with real athletes nearby. Schedule sessions, track workouts, and stay accountable.',
                    style: AppTextStyles.body(),
                  ).animate(delay: 350.ms).fadeIn(duration: 400.ms),

                  const SizedBox(height: 16),

                  // Activity pills
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['🏋️ Gym', '🏃 Running', '⚡ Hyrox', '🥊 Boxing', '🏊 Swimming']
                        .asMap().entries.map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface2,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: AppColors.border2),
                          ),
                          child: Text(e.value, style: AppTextStyles.bodySM()),
                        ).animate(delay: Duration(milliseconds: 400 + e.key * 80)).fadeIn().slideY(begin: 0.3)
                    ).toList(),
                  ),

                  const SizedBox(height: 48),

                  // CTA buttons
                  PrimaryButton(
                    label: 'Get Started',
                    onPressed: () => context.push(AppRoutesPath.register),
                  ).animate(delay: 600.ms).fadeIn(duration: 300.ms).slideY(begin: 0.3),

                  const SizedBox(height: 12),

                  GhostButton(
                    label: 'Sign In',
                    onPressed: () => context.push(AppRoutesPath.login),
                  ).animate(delay: 700.ms).fadeIn(duration: 300.ms),

                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      '🔒 Verified athletes only · ID required',
                      style: AppTextStyles.caption(),
                    ),
                  ).animate(delay: 800.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
